# Using official ubuntu docker image
FROM ubuntu:20.04

ENV BUILD_DIR=/build
ENV INSTALL_PREFIX=/usr/local
ENV CC=/usr/bin/gcc
ENV FC=/usr/bin/gfortran
ENV CXX=/usr/bin/g++
ENV MAKE_JOBS="-j8"

# Install git, zip, python-pip, cmake, g++, zlib, libssl, libcurl, java, maven via apt
# Specify DEBIAN_FRONTEND and TZ to prevent tzdata hanging
RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND="noninteractive" TZ="America/Los_Angeles" apt-get install -y build-essential gfortran git zip curl wget python3 python3-pip cmake zlib1g-dev libssl-dev libcurl4-openssl-dev openjdk-8-jdk doxygen ninja-build tar gzip libsz2 m4 libtool-bin

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# Install maven
RUN apt-get install -y maven

# Install awscli
RUN pip install awscli --upgrade

# Install AWS SDK CPP
ENV AWS_SDK_DIR=${AWS_SDK_DIR}
RUN git clone --recurse-submodules https://github.com/aws/aws-sdk-cpp && \
    cd aws-sdk-cpp && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=${AWS_SDK_DIR} -DBUILD_ONLY="s3" -DCMAKE_POLICY_DEFAULT_CMP0075=NEW -DENABLE_UNITY_BUILD=ON -DENABLE_TESTING=OFF -DSIMPLE_INSTALL=ON -DCMAKE_INSTALL_LIBDIR=lib && \
    make ${MAKE_JOBS} && \
    make install

WORKDIR ${BUILD_DIR}

# Install Blosc
ENV BLOSC_DIR=${INSTALL_PREFIX}/c-blosc
RUN git clone https://github.com/Blosc/c-blosc && \
    cd c-blosc && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=${BLOSC_DIR} && \
    cmake --build . && \
    ctest && \
    cmake --build . --target install

WORKDIR ${BUILD_DIR}

# Install HDF5 w/ Fortran
ENV HDF5_VERSION="1_12_2"
ENV HDF5DIR=${INSTALL_PREFIX}/hdf5-${HDF5_VERSION}
RUN curl -LO https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-${HDF5_VERSION}.tar.gz && \
    tar xzf hdf5-${HDF5_VERSION}.tar.gz -C . && \
    cd hdf5-hdf5-${HDF5_VERSION} && \
    ./configure --prefix=${HDF5DIR} --enable-fortran && \
    make ${MAKE_JOBS} && \
    make check && \
    make install && \
    make check-install
ENV LD_LIBRARY_PATH=${HDF5DIR}/lib

WORKDIR ${BUILD_DIR}

# Install NetCDF-C
RUN git clone https://github.com/unidata/netcdf-c

WORKDIR netcdf-c
ENV NCDIR=${INSTALL_PREFIX}/netcdf
# Requires use of specific commit and modification of CMakeLists.txt for now...
ENV NC_COMMIT=526552034
RUN git checkout ${NC_COMMIT} && \
    sed -i 's/\!MSVC/NOT MSVC/' CMakeLists.txt && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_PREFIX_PATH="${HDF5DIR};${AWS_SDK_DIR}/lib/cmake;${AWS_SDK_DIR}/lib/aws-crt-cpp/cmake;${AWS_SDK_DIR}/lib/aws-c-http/cmake;${AWS_SDK_DIR}/lib/aws-c-io/cmake;${AWS_SDK_DIR}/lib/s2n/cmake;${AWS_SDK_DIR}/lib/aws-c-common/cmake;${AWS_SDK_DIR}/lib/aws-c-cal/cmake;${AWS_SDK_DIR}/lib/aws-c-compression/cmake;${AWS_SDK_DIR}/lib/aws-c-mqtt/cmake;${AWS_SDK_DIR}/lib/aws-c-auth;${AWS_SDK_DIR}/lib/aws-c-sdkutils/cmake;${AWS_SDK_DIR}/lib/aws-c-event-stream/cmake;${AWS_SDK_DIR}/lib/aws-checksums/cmake;${AWS_SDK_DIR}/lib/aws-c-s3/cmake" -DCMAKE_INSTALL_PREFIX=${NCDIR} -DENABLE_BLOSC=ON -DBlosc_ROOT=${BLOSC_DIR} -DHDF5_LIBRARIES=${INSTALL_PREFIX}/hdf5-${HDF5_VERSION}/lib -DHDF5_INCLUDE_DIRS=${INSTALL_PREFIX}/hdf5-${HDF5_VERSION}/include -DENABLE_NCZARR=ON -DENABLE_NCZARR_S3=ON -DAWSSDK_DIR=${AWS_SDK_DIR} &&\
    make ${MAKE_JOBS} && \
    make install

# Copy plugin directory from NetCDF build location to install location
RUN cp -r ${BUILD_DIR}/netcdf-c/build/plugins/ ${NCDIR}
# Set HDF5_PLUGIN_PATH env variable
ENV HDF5_PLUGIN_PATH=${NCDIR}/plugins

WORKDIR ${BUILD_DIR}

# Install NetCDF Fortran
ENV NF_VERSION=4.5.4
ENV LD_LIBRARY_PATH="${NCDIR}/lib:${LD_LIBRARY_PATH}"
RUN curl -LO https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v${NF_VERSION}.tar.gz && \
    tar xzf v${NF_VERSION}.tar.gz -C .
WORKDIR netcdf-fortran-${NF_VERSION}
RUN CPPFLAGS=-I${NCDIR}/include LDFLAGS=-L${NCDIR}/lib ./configure --prefix=${NCDIR} && \
    make ${MAKE_JOBS} && \
    make install

WORKDIR ${BUILD_DIR}

# Clean up
WORKDIR /
RUN rm -rf ${BUILD_DIR}

# Copy test files into container
RUN mkdir netcdf_zarr_expl
WORKDIR netcdf_zarr_expl
COPY . .
RUN tar xzf zarr_files.tar.gz -C .
RUN make