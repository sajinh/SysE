! This is adapted from the Fortran source available at
! http://www.mmm.ucar.edu/wrf/OnLineTutorial/Basics/IM_files/sample.f90
!
!====================================================================================!
!                                                                                    !
! Information you need to know about your data:                                !
!    Time at which data is valid                                                     !
!    Forecast time of the data                                                       !
!    Source of data - you can make something up, it is never used                    !
!    Field name - NOTE THEY NEED TO MATCH THOSE EXPECTED BY METGRID                  !
!    Units of field                                                                  !
!    Description of data                                                             !
!    Level of data - Pa, 200100 Pa is used for surface, and 201300 Pa is used        !
!          for sea-level pressure                                                    !
!    X dimension                                                                     !
!    Y dimension                                                                     !
!    Data projection - only recognize                                                !
!         0:  Cylindrical Equidistant (Lat/lon) projection.                          !
!         1:  Mercator projection.                                                   !
!         3:  Lambert-conformal projection.                                          !
!         4:  Gaussian projection.                                                   !
!         5:  Polar-stereographic projection.                                        !
!    Start location of data - "CENTER", "SWCORNER". "SWCORNER" is typical            !
!    Start lat & long of data                                                        !
!    Lat/Lon increment                                                               !
!    Number of latitudes north of equator (for Gaussian grids)                       !
!    Grid-spacing in x/y                                                             !
!    Center long                                                                     !
!    truelat1/2                                                                      !
!    Has the winds been rotated                                                      !
!====================================================================================!

subroutine query_intermediate_file(funit,hdate0, field0, units0, desc0, &
  map_source0, xlvl, nx, ny, iproj)

  implicit none

! Declarations:

  character*46 hdate0, field0, units0, desc0, map_source0
  integer funit
  integer :: ierr

  integer :: IFV
  character(len=24) :: HDATE
  real              :: XFCST
  character(len=8)  :: STARTLOC
  character(len=9)  :: FIELD
  character(len=25) :: UNITS
  character(len=46) :: DESC
  character(len=32) :: MAP_SOURCE
  real              :: XLVL
  integer           :: NX
  integer           :: NY
  integer           :: IPROJ

     read (FUNIT, IOSTAT=IERR) IFV

     ! WRITE the second record, common to all projections:

     read (FUNIT) HDATE, XFCST, MAP_SOURCE, FIELD, UNITS, DESC, XLVL, NX, NY, IPROJ

  hdate0=hdate
  field0=field
  units0=units
  desc0=desc
  map_source0=map_source
end subroutine query_intermediate_file
