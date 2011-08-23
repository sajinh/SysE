C NCLFORTSTART
        subroutine ann_harm(nhar,var,nmd,sst,low,nmon,ndims,ilen)
        real var(nmd)
	real sst(ndims,ilen), low(ndims,ilen)
	real a(nhar), b(nhar), rcas(nhar,ilen), rsyn(nhar,ilen)
C NCLEND
c	program harfil
c	removes the required number of harmonics from the data
c  Function Parameter reference
c  nhar =  integer; number of harmonics to remove
c  var  =  float  ; reduced one dimensional input data array
c                 ; we estimate the seasonal cycle from
c                 ; this data
c                 ; the input data contains ilen months of
c                 ; data; each of the ilen units could contain
c                 ; a multi-dimensional array representing
c                 ; n-dimensional data
c                 ; to make this routine more general, the n-dimensional
c                 ; data is flattened out into a 1-D array
c                 ; and written out sequentially
c                 ; for an example see
c sst = float     ; two dimensional output array
c!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
c  Read the data into array SST
        
        do mon=1,ilen
        do i = 1,ndims
        sst(i,mon)=0.0
        low(i,mon)=0.0
        end do
        end do

        k=0
        pi=3.1415 
        print *, pi

	do mon=1,nmon
	do i=1,ndims
        k=k+1
	sst(i,mon)=var(k)
	enddo
	end do
c!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

c Calculate the shapes of sine and cos waves at the different
c harmonic frequencies

	do mon = 1, ilen
	 do L = 1,nhar
	 rcas(L,mon) = cos((2*pi*L/ilen)*mon)
	 rsyn(L,mon) = sin((2*pi*L/ilen)*mon)
	 enddo
	enddo


	do i = 1,ndims
	  do L = 1,nhar
	  a(L) = 0.0
	  b(L) = 0.0
c	Calculate the Lth harmonic component
	    do mon = 1,ilen
	    a(L) = a(L) + sst(i,mon)*rcas(L,mon)
	    b(L) = b(L) + sst(i,mon)*rsyn(L,mon)
	    enddo
	  a(L) = a(L) * 2 / float(ilen)
	  b(L) = b(L) * 2 / float(ilen)
	  enddo

c	Now reconstruct the time-series with a specified no of harmonics
c	This reconstructs the seasonal cycle

	do mon = 1,ilen
	   do L = 1,nhar
           low(i,mon) = low(i,mon)  
     &                  +  a(L) * rcas(L,mon)
     &                  +  b(L) * rsyn(L,mon)

	    end do
	 end do

	end do

        k=0
        do mon=1,nmon
        do i = 1,ndims
        k=k+1
c        ann_cycle(k)=low(i,mon)
c        var(k)=sst(i,mon)
        var(k)=low(i,mon)
        end do
        end do

1000    continue
	return
	end
