C********************************************************************
C+27B SUBROUTINE HSTWAFLL +++
C   # Calculate horizontal component of wave activity flux on latitude-
C     longitude grid (MLON x MLAT), which is a product of the wave  
C     activity density and group velocity, based on a formulation 
C     by Takaya and Nakamura (1997):
C       WAXFLX =0.5*[UB*(V*V-PHI*dVx) + VB*(PHI*dUx-U*V)]/BWSPD (zonal comp)
C       WAYFLX =0.5*[UB*(PHI*dUx-U*V) + VB*(U*U+PHI*dUy)]/BWSPD (merid. comp)
C     where BWSPD is the wind speed of the basic flow:
C       BWSPD=sqrt(UB*UB + VB*VB)
C     with perturbation velocity (U,V) and their x and y derivatives,
C     UNAVL: a huge real number to represent data missing points,
C            but assume no missing points in wind and height anomalies.
C
C     NOTE: This formulation can be used for both barotropic and
C           baroclinic situations.
C     NOTE: No evaluation will be made and filled with UNAVL
C           where BWSPD < UBMIN (m/s). By definition no flux is 
C           evaluated at the Poles (set to zero).
C     NOTE: No evaluation will be made either and filled with UNAVL
C           in the tropics where |lat.|.le.DLATTRP and QG theory breaks
C           down.  This treatment is available only if height anomalies
C           rather than genuine streamfunction anomalies are given in ZA 
C           (set HS='h').  If the latter is given (set HS='s'), evaluation
C           will be made even at the equator.
C     NOTE: Give latitude in degrees for all meridinal grid.  Assume
C           LAT=1,MLAT correspond to the Poles. Also assume
C           uniform longitudinal interval DLONI (in deg.) measuring
C           west to east completely around a latitude circle.
C********************************************************************
C
C NCLFORTSTART
      SUBROUTINE HSTWAFLL (HS,MLAT,MLON,UNAVL,DLONI,UBMIN,DLATTRP,
     &                     DLAT,UB,VB,ZA,UA,VA,WAXFLX,WAYFLX)
C
c      parameter (GRV=9.8, TDAY=86164., ERD=6.371E+06)  ! g, f(43N), earth rad. 
      real*4 DLAT(MLAT)			! latitude (deg.)
      real*4 UB(MLON,MLAT),VB(MLON,MLAT)     ! basic wind velocity
      real*4 ZA(MLON,MLAT)        	! height anomalies or streamfunc anomalies
      real*4 UA(MLON,MLAT),VA(MLON,MLAT)  ! anomalous U, its gradient
      real*4 WAXFLX(MLON,MLAT),WAYFLX(MLON,MLAT)  ! wave activity fluxes
      character*1 HS   
C NCLEND
C
        GRV=9.8
        TDAY=86164.
        ERD=6.371E+06

      PAI=ACOS (-1.)
      DGRD=PAI/180.
      GFCTR=1./ERD
      if (HS.eq.'h') GCFCTR=0.25*GRV*TDAY/(PAI*ERD)
      RLONI2=2.*DLONI*DGRD
C
      do 10 LAT=1,MLAT   
        RLAT=DGRD*DLAT(LAT)
C
        if (HS.eq.'h') then
          if (abs(DLAT(LAT)).le.DLATTRP) then
            do 11 LON=1,MLON			! set missing values in the tropics
              WAXFLX(LON,LAT)=UNAVL
              WAYFLX(LON,LAT)=UNAVL
  11        continue				
            go to 10
          endif
        endif
C      
        if ((LAT.eq.1).or.(LAT.eq.MLAT)) then
          do 12 LON=1,MLON			! set no flux at the Poles
            WAXFLX(LON,LAT)=0.
            WAYFLX(LON,LAT)=0.
  12      continue				
          go to 10
        endif
C
        LATF=LAT+1
        LATB=LAT-1
        DLATI2=DLAT(LATF)-DLAT(LATB)
        RLATI2=DGRD*DLATI2
C				  ! scaling factor for PHI*d( )/dx or PHI*d( )/dy
        if (HS.eq.'h') GFCTR=GCFCTR/SIN(RLAT)      ! factor = g/{a*f(lat.)}
        COSLAT=COS(RLAT)
C
        do 20 LON=1,MLON
          WAXFLX(LON,LAT)=UNAVL
          WAYFLX(LON,LAT)=UNAVL
C
          UBL=UB(LON,LAT)
          VBL=VB(LON,LAT)
c          if (UBL.le.UBMIN) go to 20  ! missing flux where UB < UBMIN (tnf2)
          if (UBL.le.UBMIN) UBL=2.  ! if UB < UBMIN then UB=+2m/s (tnf4)
          BWSPD=sqrt(UBL*UBL+VBL*VBL)
c          if (VBL.le.0.) VBL=0.  ! if VB < 0 then VB=0m/s in tnf4 condition (tnf5)
c          if (BWSPD.le.UBMIN) go to 20  ! missing flux where |UB| < UBMIN (tnf3)
C
          LONE=LON+1
          if (LONE.gt.MLON) LONE=1
          LONW=LON-1
          if (LONW.lt.1) LONW=MLON
          DXFCTR=GFCTR/(RLONI2*COSLAT)
          DYFCTR=GFCTR/RLATI2
          UAL=UA(LON,LAT)
          VAL=VA(LON,LAT)
          PHIAL=ZA(LON,LAT)
          DUDX=DXFCTR*(UA(LONE,LAT)-UA(LONW,LAT))
          DVDX=DXFCTR*(VA(LONE,LAT)-VA(LONW,LAT))
          DUDY=DYFCTR*(UA(LON,LATF)-UA(LON,LATB))
C						   ! PHIA*dUA/dx-UA*VA
          UVL=DUDX*PHIAL-UAL*VAL
          WAFX=UBL*(VAL*VAL-DVDX*PHIAL)+VBL*UVL
          WAFY=VBL*(UAL*UAL+DUDY*PHIAL)+UBL*UVL
C
          FCTWAF=0.5*COSLAT/BWSPD        ! areal scaling factor
          WAXFLX(LON,LAT)=FCTWAF*WAFX
          WAYFLX(LON,LAT)=FCTWAF*WAFY
  20    continue
  10  continue
      return
      end
C
C********************************************************************
C+27C SUBROUTINE PSTWAFLL +++
C   # Calculate vertical component of wave activity flux on P-coordinate,
C     a product of the wave activity density and group velocity, using
C     a formulation by Takaya and Nakamura (1997):
C      -WAPFLX =0.5f*[UB*(V*TH-PHI*dTHx) + VB*(U*TH+PHI*dTHdy)]/(BWSPD*SP)
C     where BWSPD is the wind speed of the basic flow:
C       BWSPD=sqrt(UB*UB + VB*VB)
C     with perturbation velocity (U,V) and their x and y derivatives,
C     and perturbation streamfunction (PHI=gZ/f).  TH denotes perturbation
C     potential temperature, and SP = -dTHB/dp is a static stability
C     paremeter.
C
C     NOTE: Sign of the component is reversed so that the positive 
C           denotes upward.
C     NOTE: temperatures have to be converted to potential temperatures
C           (mean, anomalies) in advance.
C     NOTE: No evaluation will be made and filled with UNAVL
C           where BWSPD < UBMIN (m/s). By definition no flux is 
C           evaluated at the Poles (set to zero).
C     NOTE: No evaluation will be made either and filled with UNAVL
C           in the tropics where |lat.|.le.DLATTRP and QG theory breaks
C           down.  This treatment is available only if height anomalies
C           rather than genuine streamfunction anomalies are given in ZA 
C           (set HS='h').  If the latter is given (set HS='s'), evaluation
C           will be made even at the equator.
C     NOTE: Give latitude in degrees for all meridinal grid.  Assume
C           LAT=1,MLAT correspond to the Poles. Also assume
C           uniform longitudinal interval DLONI (in deg.) measuring
C           west to east completely around a latitude circle.
C********************************************************************
C
      SUBROUTINE PSTWAFLL (HS,MLAT,MLON,UNAVL,PU,PL,DLONI,UBMIN,DLATTRP,
     &                     DLAT,UB,VB,THUB,THLB,ZA,UA,VA,THA,WAPFLX)
C
c      parameter (GRV=9.8, TDAY=86164., ERD=6.371E+06)  ! g, f(43N), earth rad. 
      real*4 DLAT(MLAT)			! latitude (deg.)
      real*4 UB(MLON,MLAT),VB(MLON,MLAT)     ! basic wind velocity
      real*4 THUB(MLON,MLAT),THLB(MLON,MLAT)   ! mean pot. temp. upper/lower
      real*4 ZA(MLON,MLAT)        	! height anomalies or streamfunc anomalies
      real*4 UA(MLON,MLAT),VA(MLON,MLAT)  ! anomalous U, its gradient
      real*4 THA(MLON,MLAT)        	! potential temperature anomalies
      real*4 WAPFLX(MLON,MLAT)	  ! wave activity flux (pos: upward)
      character*1 HS   
C
        GRV=9.8
        TDAY=86164.
        ERD=6.371E+06 

      if (PU.ge.PL) then
        write (*,*) '==> Error!  Pressure at two levels are reversed.'
        stop
      endif
      DP=100.*(PL-PU)    ! pressure difference (Pa) between upper & lower levels
C
      PAI=ACOS (-1.)
      DGRD=PAI/180.
      F90=4.*PAI/TDAY
      GFCTR=1./ERD
      if (HS.eq.'h') GCFCTR=GRV/(F90*ERD)
      RLONI2=2.*DLONI*DGRD
C
      do 10 LAT=1,MLAT   
        RLAT=DGRD*DLAT(LAT)
        CORIOL=F90*SIN(RLAT)
C
        if (HS.eq.'h') then
          if (abs(DLAT(LAT)).le.DLATTRP) then
            do 11 LON=1,MLON			! set missing values in the tropics
              WAPFLX(LON,LAT)=UNAVL
  11        continue				
            go to 10
          endif
        endif
C      
        if ((LAT.eq.1).or.(LAT.eq.MLAT)) then
          do 12 LON=1,MLON			! set no flux at the Poles
            WAPFLX(LON,LAT)=0.
  12      continue				
          go to 10
        endif
C
        LATF=LAT+1
        LATB=LAT-1
        DLATI2=DLAT(LATF)-DLAT(LATB)
        RLATI2=DGRD*DLATI2
C				  ! scaling factor for PHI*d( )/dx or PHI*d( )/dy
        if (HS.eq.'h') GFCTR=GCFCTR/SIN(RLAT)      ! factor = g/{a*f(lat.)}
        COSLAT=COS(RLAT)
C
        do 20 LON=1,MLON
          WAPFLX(LON,LAT)=UNAVL
C
          UBL=UB(LON,LAT)
          VBL=VB(LON,LAT)
c          if (UBL.le.UBMIN) go to 20  ! missing flux where UB < UBMIN (tnf2)
          if (UBL.le.UBMIN) UBL=2.  ! if UB < UBMIN then UB=+2m/s (tnf4)
          BWSPD=sqrt(UBL*UBL+VBL*VBL)
c          if (VBL.le.0.) VBL=0.  ! if VB < 0 then VB=0m/s in tnf4 condition (tnf5)
c          if (BWSPD.le.UBMIN) go to 20  ! missing flux where |UB| < UBMIN
C
          STAB=(THUB(LON,LAT)-THLB(LON,LAT))/DP   ! mean stability
          if (STAB.le.0.) go to 20  ! missing flux where statically unstable (tnf3)
C
          LONE=LON+1
          if (LONE.gt.MLON) LONE=1
          LONW=LON-1
          if (LONW.lt.1) LONW=MLON
          DXFCTR=GFCTR/(RLONI2*COSLAT)
          DYFCTR=GFCTR/RLATI2
          UAL=UA(LON,LAT)
          VAL=VA(LON,LAT)
          THAL=THA(LON,LAT)
          PHIAL=ZA(LON,LAT)
          DTHDX=DXFCTR*(THA(LONE,LAT)-THA(LONW,LAT))
          DTHDY=DYFCTR*(THA(LON,LATF)-THA(LON,LATB))
C						   
          WAFP=UBL*(VAL*THAL-DTHDX*PHIAL)-VBL*(UAL*THAL+DTHDY*PHIAL)
C
          FCTWAF=0.5*CORIOL*COSLAT/(BWSPD*STAB)        ! areal scaling factor
          WAPFLX(LON,LAT)=FCTWAF*WAFP
  20    continue
  10  continue
      return
      end
