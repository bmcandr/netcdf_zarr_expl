! This is part of the netCDF package.
! Copyright 2006 University Corporation for Atmospheric Research/Unidata.
! See COPYRIGHT file for conditions of use.
      
! This is a simple example which reads a small dummy array, from a
! Zarr file created by the xarray Python library based on the netCDF file
! created by the companion program simple_xy_wr.f90.
      
! This is intended to illustrate the use of the netCDF fortran 77
! API. This example program is part of the netCDF tutorial, which can
! be found at:
! http://www.unidata.ucar.edu/software/netcdf/docs/netcdf-tutorial
      
! Full documentation of the netCDF Fortran 90 API can be found at:
! http://www.unidata.ucar.edu/software/netcdf/docs/netcdf-f90

! $Id: simple_xy_zarr_rd.f90,v 1.7 2006/12/09 18:44:58 russ Exp $

program simple_xy_zarr_rd
  use netcdf
  implicit none

  ! This is the name of the Zarr store we will read. 
  character (len = *), parameter ::  FILE_NAME = "file://inputs/simple_xy_xarray.zarr#mode=zarr,file"

  ! We are reading 2D data. 
  integer, parameter :: NX = 6, NY = 12
  integer(kind=8) :: data_in(NY, NX)

  ! This will be the netCDF ID for the file and data variable.
  integer :: ncid, varid, filterid, nparams

  ! Loop indexes, and error handling.
  integer :: x, y

  ! Open the file. NF90_NOWRITE tells netCDF we want read-only access to
  ! the file.
  call check( nf90_open(FILE_NAME, NF90_NOWRITE, ncid), "Failed at nf90_open: " // FILE_NAME )

  ! Get the varid of the data variable, based on its name.
  call check( nf90_inq_varid(ncid, "data", varid), "Failed at nf90_inq_varid" )

  ! Read the data.
  call check( nf90_get_var(ncid, varid, data_in), "Failed at nf90_get_var" )

  ! Check the data.
  do x = 1, NX
     do y = 1, NY
       print *, "data_in(", y, ", ", x, ") = ", data_in(y, x)
     end do
  end do

  ! Close the file, freeing all resources.
  call check( nf90_close(ncid), "Failed at nf90_close" )

  print *,"*** SUCCESS reading example file ", FILE_NAME, "! "

contains
  subroutine check(status, msg)
    integer, intent ( in) :: status
    character (len=*) :: msg
    
    if(status /= nf90_noerr) then 
      print *, trim(nf90_strerror(status))
      stop "Stopped: " // msg
    end if
  end subroutine check  
end program simple_xy_zarr_rd
