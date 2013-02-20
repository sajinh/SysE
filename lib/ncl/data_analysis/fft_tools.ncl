function Daniell_Window(nsmooth)
begin
        dan_win=new(nsmooth,"double")
        dan_win(1:nsmooth-2)=1/int2flt(nsmooth-1)
        dan_win(0)=1/(2*int2flt(nsmooth-1))
        dan_win(nsmooth-1)=dan_win(0)
        return dan_win
end

function Calculate_Dof(dan_win,ntim,npad,ntaper)
begin
        cp=int2flt(ntim+npad)/int2flt(ntim)
        ct=128*1.d0-(93*1.d0*ntaper)
        ct=ct/(2.d0*(8-5*ntaper)^2)
        gu2=sum(dan_win^2)
        gw2=ct*cp*gu2
        df=doubletoint(2.d0/gw2)
        print("Degrees of Freedom ::: "+df)
return df
end

function rspec(var,freq)
begin

	ndims=dimsizes(dimsizes(var))
	if (ndims.gt.4) then
	print("This function does not currently handle variables with dimensions greater than 4")
	exit
	end if

        acr = esacr(var,1)
	if (ndims.eq.1) then
        lag1=acr(1)
	rho=new( (/1,1/),typeof(lag1))
	end if
	;
	if (ndims.eq.2) then
        lag1=acr(:,1)
	n1=dimsizes(lag1)
	rho=new( (/n1,1/),typeof(lag1))
	end if
	;
	if (ndims.eq.3) then
        lag1=acr(:,:,1)
	n1=dimsizes(lag1(:,0))
	n2=dimsizes(lag1(0,:))
	rho=new( (/n1,n2,1/),typeof(lag1))
	end if
	;
	if (ndims.eq.4) then
        lag1=acr(:,:,:,1)
	n1=dimsizes(lag1(:,0,0,0))
	n2=dimsizes(lag1(0,:,0,0))
	n3=dimsizes(lag1(0,0,:,0))
	rho=new( (/n1,n2,n3,1/),typeof(lag1))
	end if
	;.................................




	;---------------------------------
	;	
	;	..........................
	
        rho = lag1
        pi=4.d0*atan(1.d0)
	omega=new((/1,dimsizes(freq)/),typeof(freq))
        omega=freq*2.0*dble2flt(pi)
        rhosqr=rho*rho
        tworho=2*rho
	
	rank=dimsizes(dimsizes(rho))
	if (rank.eq.3) then
	rspc=new( (/n1,n2,dimsizes(freq)/), typeof(freq))
	do i = 0,n1-1
	rspc(i,:,:)=tworho(i,:,:)#cos(omega)
	end do
	end if

	if (rank.eq.4) then
	rspc=new( (/n1,n2,n3,dimsizes(freq)/), typeof(freq))
	do i = 0,n1-1
	  do j = 0,n2-1
	  rspc(i,j,:,:)=tworho(i,j,:,:)#cos(omega)
	  end do
	end do
	end if

	if (rank.lt.3) then	
	rspc=tworho#cos(omega)
	end if

	if (rank.eq.4) then
        rspc=(1-conform(rspc,rhosqr(:,:,:,0),(/0,1,2/)) ) /  \
		(1-rspc+conform(rspc,rhosqr(:,:,:,0),(/0,1,2/)) )
	end if

	if (rank.eq.3) then
        rspc=(1-conform(rspc,rhosqr(:,:,0),(/0,1/)) ) /  \
		(1-rspc+conform(rspc,rhosqr(:,:,0),(/0,1/)) )
	end if

	if (rank.lt.3) then
        rspc=(1-conform(rspc,rhosqr(:,0),0) ) /  \
		(1-rspc+conform(rspc,rhosqr(:,0),0) )
	end if
	
        return rspc
end
