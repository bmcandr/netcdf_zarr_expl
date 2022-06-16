INPUT        = simple_xy_xarray.zarr
FORTRAN_EXEC = simple_xy_zarr_rd_fortran
C_EXEC       = simple_xy_zarr_rd_c

ALL: $(INPUT) $(FORTRAN_EXEC) $(C_EXEC)

$(INPUT): zarr_files.tar.gz
	tar xzf $< -C .

$(FORTRAN_EXEC): simple_xy_zarr_rd.f90
	$(FC) $< -o $@  -I${NCDIR}/include -L${NCDIR}/lib -lnetcdff -lnetcdf -I${HDF5DIR}/include -lhdf5_hl -lhdf5 -L${HDF5DIR}/lib

$(C_EXEC): simple_xy_zarr_rd.c
	$(CC) $< -o $@ -I${NCDIR}/include -L${NCDIR}/lib -lnetcdf -I${HDF5DIR}/include -L${HDF5DIR}/lib -lhdf5_hl -lhdf5 

.phony: clean
clean:
	rm $(FORTRAN_EXEC) $(C_EXEC)

