# Exploring Support for Zarr and S3 in NetCDF Library

This repository provides a demonstration of reading Zarr compressed with Blosc+LZ4 in Fortran 90 and C. It also attempted to demonstrate support for reading data from S3 buckets.

## Docker

The Dockerfile in this repository captures the build process for successfully building the NetCDF C and Fortran libraries with support for (1) reading Zarr stores that have been compressed with Blosc+subcompressor (e.g., LZ4) and (2) integration with the AWS SDK for C++ (specifically the SDK for accessing S3 buckets).

To build:

```
% docker build -t netcdf_zarr .
```

To run:

```
% docker run -it netcdf_zarr /bin/bash
```

Then run the demo programs:

```
./simple_xy_zarr_rd_c

...

./simple_xy_zarr_rd_fortran
```

## Install Dependencies

1. Install [AWS SDK CPP](https://github.com/aws/aws-sdk-cpp)

    **TODO:** investigate dependency requirements. Installing AWS SDK CPP goes fine, but installing NetCDF with AWS SDK support throws error related to missing dependency:
    
    ```
    CMake Error at /gpfsm/dulocal/sles12/other/cmake/3.23.1/share/cmake-3.23/Modules/FindPackageHandleStandardArgs.cmake:230 (message):
    Could NOT find crypto (missing: crypto_LIBRARY)
    ```
    
    Links:
    
    * https://github.com/aws/aws-sdk-cpp/issues/1910
    * https://docs.aws.amazon.com/sdk-for-cpp/v1/developer-guide/setup-linux.html
   
   1. Clone the master branch from GitHub and recurse all submodules:
      `git clone --recurse-submodules git@github.com:aws/aws-sdk-cpp`
      
   2. Change into the repo directory, create a build directory, and change into it:
       
       ```
       $ cd aws-sdk-cpp
       $ mkdir build
       $ cd build
       ```
      
   3. Run `cmake` and with the following options ([see here for guidance from NetCDF developers](https://github.com/Unidata/netcdf-c/blob/main/docs/nczarr.md#nix-build)):
   
       ```
       $ cmake .. -DCMAKE_INSTALL_PREFIX=${PREFIX} -DBUILD_ONLY="s3" -DCMAKE_MODULE_PATH=${PREFIX}/lib/cmake -DCMAKE_POLICY_DEFAULT_CMP0075=NEW -DENABLE_UNITY_BUILD=ON -DENABLE_TESTING=OFF -DSIMPLE_INSTALL=ON -DCMAKE_INSTALL_LIBDIR=lib
       ```
       
   4. Remove `-Werror` flags from several files named "flags.make". This flag treats all warnings as errors and causes the build to fail on Discover (and, likely, other systems).
   
       ```
       for FILE in $(find . -type f -name flags.make -exec grep -Hl "Werror" {} \;); do sed -i 's/-Werror//g' $FILE; done
       ```
   
   5. Run `make` and then `make install`.
   
2. Install [c-blosc](https://github.com/Blosc/c-blosc)
3. Install HDF5 with Fortran enabled (or point to existing installation)
4. Install netCDF-C
    1. Clone the latest master branch and checkout commit [`526552034`](https://github.com/Unidata/netcdf-c/commit/526552034cbd9bbcc013994494a50c9e19a32c21):
        
        ```
        $ git clone git@github.com:unidata/netcdf-c
        $ cd netcdf-c
        $ git checkout 526552034cbd9bbcc013994494a50c9e19a32c21
        ```
     2. Run `sed -i 's/\!MSVC/NOT MSVC/' CMakeLists.txt` (fixes an bug that prevents CMake from finding Blosc libraries).
     3. Create directory named `build/` and move into it.
     4. Run cmake with the following command (replace `path/to/<dir>` with relevant paths):
        
        ```
        $ cmake .. -DCMAKE_PREFIX_PATH=path/to/hdf5 -DCMAKE_INSTALL_PREFIX=path/to/install/dir -DENABLE_BLOSC=ON -DBlosc_ROOT=path/to/blosc -DHDF5_LIBRARIES=path/to/hdf5/lib -DENABLE_FILTER_TESTING=ON
        ```

     5. Build with `cmake --build .`
     6. Install with `make install`
     7. Copy the `plugins/` directory into the netCDF install directory.

5. Install netCDF-Fortran into same install directory as netCDF-C

## Set Environment Variables

### Set Yourself

The following environment variables must be set to use the Makefile in this repository to compile the C and F90 files:

* `FC`: the Fortran compiler used to build the above dependencies
* `CC`: the C compiler used to build the above dependencies
* `HDFDIR`: the path to your installation of the HDF5 library
* `NCDIR`: the path to your installation of the netCDF library (both C and Fortran)
* `HDF5_PLUGIN_PATH`: the path to the `plugins/` directory built by netCDF (e.g,. `$NCDIR/plugins`)

### Use Modulefile

1. Change directories into this repository.

2. If necessary, update `modules/gnu_nczarr_env` to point to your installations of HDF5 and netCDF.

3. Copy `gnu_nczarr_env` into `~/privatemodules`:

```
$ cp modules/gnu_nczarr_env ~/privatemodules
```

4. Load module with `module load gnu_nczarr_env`

## Decompress Input Files and Compile 

Run `make` to decompress the input files and compile the executables (`simple_xy_zarr_rd_c` and `simple_xy_zarr_rd_fortran`).

A netCDF file (`simple_xy.nc`) and a Zarr store (`simple_xy_xarray.zarr`) should be present in the `inputs/` directory.

Note: the `simple_xy_zarr_rd.*` source code files contained in this repository are based on `simple_xy_rd.c` and `simple_xy_rd.f90` from [the netCDF website](https://www.unidata.ucar.edu/software/netcdf/examples/programs/). The `FILE_NAME` variable has simply been modified to point to a local Zarr store using the URL format `file://simple_xy_xarray.zarr#mode=zarr,file` as described [here](https://www.unidata.ucar.edu/blogs/developer/en/entry/overview-of-zarr-support-in).

## Run the Executables

For example:

```
$ ./simple_xy_zarr_rd_fortran
 data_in(           1 ,            1 ) =                     0
 data_in(           2 ,            1 ) =                     1
 data_in(           3 ,            1 ) =                     2
 data_in(           4 ,            1 ) =                     3
 data_in(           5 ,            1 ) =                     4
 data_in(           6 ,            1 ) =                     5
 data_in(           7 ,            1 ) =                     6
 data_in(           8 ,            1 ) =                     7
 data_in(           9 ,            1 ) =                     8
 data_in(          10 ,            1 ) =                     9
 data_in(          11 ,            1 ) =                    10
 data_in(          12 ,            1 ) =                    11
 data_in(           1 ,            2 ) =                    12
 data_in(           2 ,            2 ) =                    13
 data_in(           3 ,            2 ) =                    14
 data_in(           4 ,            2 ) =                    15
 data_in(           5 ,            2 ) =                    16
 data_in(           6 ,            2 ) =                    17
 data_in(           7 ,            2 ) =                    18
 data_in(           8 ,            2 ) =                    19
 data_in(           9 ,            2 ) =                    20
 data_in(          10 ,            2 ) =                    21
 data_in(          11 ,            2 ) =                    22
 data_in(          12 ,            2 ) =                    23
 data_in(           1 ,            3 ) =                    24
 data_in(           2 ,            3 ) =                    25
 data_in(           3 ,            3 ) =                    26
 data_in(           4 ,            3 ) =                    27
 data_in(           5 ,            3 ) =                    28
 data_in(           6 ,            3 ) =                    29
 data_in(           7 ,            3 ) =                    30
 data_in(           8 ,            3 ) =                    31
 data_in(           9 ,            3 ) =                    32
 data_in(          10 ,            3 ) =                    33
 data_in(          11 ,            3 ) =                    34
 data_in(          12 ,            3 ) =                    35
 data_in(           1 ,            4 ) =                    36
 data_in(           2 ,            4 ) =                    37
 data_in(           3 ,            4 ) =                    38
 data_in(           4 ,            4 ) =                    39
 data_in(           5 ,            4 ) =                    40
 data_in(           6 ,            4 ) =                    41
 data_in(           7 ,            4 ) =                    42
 data_in(           8 ,            4 ) =                    43
 data_in(           9 ,            4 ) =                    44
 data_in(          10 ,            4 ) =                    45
 data_in(          11 ,            4 ) =                    46
 data_in(          12 ,            4 ) =                    47
 data_in(           1 ,            5 ) =                    48
 data_in(           2 ,            5 ) =                    49
 data_in(           3 ,            5 ) =                    50
 data_in(           4 ,            5 ) =                    51
 data_in(           5 ,            5 ) =                    52
 data_in(           6 ,            5 ) =                    53
 data_in(           7 ,            5 ) =                    54
 data_in(           8 ,            5 ) =                    55
 data_in(           9 ,            5 ) =                    56
 data_in(          10 ,            5 ) =                    57
 data_in(          11 ,            5 ) =                    58
 data_in(          12 ,            5 ) =                    59
 data_in(           1 ,            6 ) =                    60
 data_in(           2 ,            6 ) =                    61
 data_in(           3 ,            6 ) =                    62
 data_in(           4 ,            6 ) =                    63
 data_in(           5 ,            6 ) =                    64
 data_in(           6 ,            6 ) =                    65
 data_in(           7 ,            6 ) =                    66
 data_in(           8 ,            6 ) =                    67
 data_in(           9 ,            6 ) =                    68
 data_in(          10 ,            6 ) =                    69
 data_in(          11 ,            6 ) =                    70
 data_in(          12 ,            6 ) =                    71
 ```
