! Adapted from CAM2WRF main routine of Eli Tziperman <eli@EPS.Harvard.edu>
! CAM2WRF can be downloaded from 
! http://www.seas.harvard.edu/climate/eli/Downloads/CAM2WRF.tgz
Subroutine interpolate_to_pressure_levels(nz_WRF &
     ,nx_CAM,ny_CAM,nz_CAM &
     ,PS,P_int,log_P_int,log_P &
     ,field_data,field_data_int)

  implicit none
  integer :: nz_WRF
  integer :: nx_CAM, ny_CAM, nz_CAM
  real :: PS(nx_CAM,ny_CAM)
  real :: P_int(nz_WRF)
  real :: log_P_int(nz_WRF) 
  real :: log_P(nx_CAM,ny_CAM,nz_CAM)
  real :: field_data (nx_CAM,ny_CAM,nz_CAM)
  real :: field_data_int(nx_CAM,ny_CAM,nz_WRF)

  ! local variables
  integer :: i,j,k
  real*8 :: X(nz_CAM),Y(nz_CAM),Y2(nz_CAM),XINT,YINT,yp1,ypn
  
  ! interpolate from sigma to pressure coordinates:
  ! "natural" b.c.:
  yp1=2.d30; ypn=2.d30
     do j=1,ny_CAM; do i=1,nx_CAM; 
        X=log_P(i,j,:)
        Y=field_data(i,j,:)
        call spline(X,Y,nz_CAM,yp1,ypn,Y2)
        do k=1,nz_WRF
           if (abs(P_int(k)-200100).le.0.01) then
              ! surface level:
              XINT=log(PS(i,j))
           else
              XINT=log_P_int(k)
           end if
           call splint(X,Y,Y2,nz_CAM,XINT,YINT)
           field_data_int(i,j,k)=YINT
        end do
     end do; end do;

  return
end subroutine interpolate_to_pressure_levels

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE spline(x,y,n,yp1,ypn,y2) 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  implicit none
  INTEGER :: n
  INTEGER, parameter :: NMAX=500
  REAL*8 :: yp1,ypn,x(n),y(n),y2(n) 
  INTEGER :: i,k
  REAL*8 :: p,qn,sig,un,u(NMAX)
  if (yp1.gt..99e30) then
     y2(1)=0.
     u(1)=0.
  else
     y2(1)=-0.5
     u(1)=(3./(x(2)-x(1)))*((y(2)-y(1))/(x(2)-x(1))-yp1)
  end if
  do i=2,n-1
     sig=(x(i)-x(i-1))/(x(i+1)-x(i-1))
     p=sig*y2(i-1)+2.
     y2(i)=(sig-1.)/p
     u(i)=(6.*((y(i+1)-y(i))/(x(i+1)-x(i))-(y(i)-y(i-1)) &
          /(x(i)-x(i-1)))/(x(i+1)-x(i-1))-sig*u(i-1))/p
  end do

  if (ypn.gt..99e30) then
     qn=0.
     un=0.
  else
     qn=0.5 
     un=(3./(x(n)-x(n-1)))*(ypn-(y(n)-y(n-1))/(x(n)-x(n-1)))
  end if
  y2(n)=(un-qn*u(n-1))/(qn*y2(n-1)+1.)
  do k=n-1,1,-1
     y2(k)=y2(k)*y2(k+1)+u(k)
  end do
  return
end SUBROUTINE spline


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
SUBROUTINE splint(xa,ya,y2a,n,x,y) 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  implicit none
  INTEGER :: n 
  REAL*8 :: x,y,xa(n),y2a(n),ya(n)
  INTEGER :: k,khi,klo
  REAL*8 :: a,b,h

  ! Eli: avoid actual extrapolation by using the end values:
  if (x<xa(1)) then
     y=ya(1);
  elseif (x>xa(n)) then
     y=ya(n);
  else
     ! Eli: end of my addition here.
     klo=1
     khi=n
1    if (khi-klo.gt.1) then
        k=(khi+klo)/2
        if(xa(k).gt.x)then
           khi=k
        else
           klo=k
        end if
        goto 1
     end if
     h=xa(khi)-xa(klo)
     !if (h.eq.0.) pause 'bad xa input in splint'
     a=(xa(khi)-x)/h
     b=(x-xa(klo))/h
     y=a*ya(klo)+b*ya(khi)+ &
          ((a**3-a)*y2a(klo)+(b**3-b)*y2a(khi))*(h**2)/6.
  end if

  return 
end SUBROUTINE splint

