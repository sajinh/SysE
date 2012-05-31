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

subroutine read_intermediate_file(funit,hdate0, startloc0, field0, units0, desc0, &
  map_source0, xlvl, nx, ny, iproj, startlat, startlon, deltalat, deltalon,&
  dx, dy, xlonc, truelat1, truelat2, nlats0, slab,DEBUG)


  implicit none

! Declarations:

  character*(*) hdate0, startloc0, field0, units0, desc0, map_source0
  integer nlats0
  integer funit
  integer :: ierr

  integer :: IFV=5
  character(len=24) :: HDATE
  real :: XFCST
  character(len=8) :: STARTLOC
  character(len=9) :: FIELD
  character(len=25) :: UNITS
  character(len=46) :: DESC
  character(len=32) :: MAP_SOURCE
  real :: XLVL
  integer :: NX
  integer :: NY
  integer :: IPROJ
  real :: STARTLAT
  real :: STARTLON
  real :: DELTALAT
  real :: DELTALON
  real :: DX
  real :: DY
  real :: XLONC
  real :: TRUELAT1
  real :: TRUELAT2
  real :: NLATS
  real :: EARTH_RADIUS = 6367470. * .001
  real :: slab(nx,ny)
  logical :: IS_WIND_EARTH_REL = .FALSE.
  logical :: DEBUG



     read (FUNIT, IOSTAT=IERR) IFV

     ! WRITE the second record, common to all projections:

     read (FUNIT) HDATE, XFCST, MAP_SOURCE, FIELD, UNITS, DESC, XLVL, NX, NY, IPROJ
     if (DEBUG) then
       print*, HDATE//"  ", XLVL, FIELD
     endif

     ! WRITE the third record, which depends on the projection:

     if (IPROJ == 0) then 

        !  This is the Cylindrical Equidistant (lat/lon) projection:
        read (FUNIT) STARTLOC, STARTLAT, STARTLON, DELTALAT, DELTALON, EARTH_RADIUS

     elseif (IPROJ == 1) then 

        ! This is the Mercator projection:
        read (FUNIT) STARTLOC, STARTLAT, STARTLON, DX, DY, TRUELAT1, EARTH_RADIUS

     elseif (IPROJ == 3) then

        ! This is the Lambert Conformal projection:
        read (FUNIT) STARTLOC, STARTLAT, STARTLON, DX, DY, XLONC, TRUELAT1, TRUELAT2, EARTH_RADIUS
        

     elseif (IPROJ == 4) then

        ! Gaussian projection                         
        read (FUNIT) STARTLOC, STARTLAT, STARTLON, NLATS, DELTALON, EARTH_RADIUS
        
     elseif (IPROJ == 5) then

        ! This is the Polar Stereographic projection:
        read (FUNIT) STARTLOC, STARTLAT, STARTLON, DX, DY, XLONC, TRUELAT1, EARTH_RADIUS

     endif

     
     read (FUNIT) IS_WIND_EARTH_REL


     read (FUNIT) slab

     ! Now that we have done all that we want to with SLAB, we need to
     ! deallocate it:

     !deallocate(slab)

  hdate0=hdate
  startloc0=startloc
  field0=field
  units0=units
  desc0=desc
  map_source0=map_source
  nlats0=nlats
end subroutine read_intermediate_file
