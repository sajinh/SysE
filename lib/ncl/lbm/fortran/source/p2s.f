C NCLFORTSTART
      subroutine prs2sig
     O         ( vout,
     I           vin, ps, nxy,nlev)
      integer nxy,nlev
      REAL*8    vout ( nxy, nlev ) !! sigma level
      REAL*8    vin  ( nxy, nlev ) !! pressure level
      REAL*8    ps   ( nxy ) !! surface pressure
C NCLEND
      
      integer nlevp, nlevs
      parameter (nlevp = 20, nlevs = 20)
      real*8    plev( nlevp )   !! ncep pressure level
      real*8    slev( nlevp )    !! 20 sigma level
      REAL*8       XMISS
      PARAMETER ( XMISS = -999. )

      DATA      slev / 0.99500,0.97999,0.94995,0.89988,0.82977,
     &                  0.74468,0.64954,0.54946,0.45447,0.36948,
     &                  0.29450,0.22953,0.17457,0.12440,0.0846830,
     &                  0.0598005,0.0449337,0.0349146,0.0248800,
     &                  0.00829901/
      DATA plev / 1000., 950., 900., 850., 700.,
     $             600., 500., 400., 300., 250.,
     $             200., 150., 100.,  70.,  50.,
     $              30.,  20.,  10.,   7.,   5.  /


        CALL P2S
     O         ( vout,
     I           vin, ps, plev, slev, nxy, nlev, nlev,XMISS)
      return
      end
      SUBROUTINE P2S
     O         ( GDO  ,
     I           GDI, GDPS, PLI, SLI, IJDIM, KMAXP, KMAXS, XMISS )
*
*   [PARAM] 
      INTEGER    IJDIM
      INTEGER    KMAXP, KMAXS
*   [OUTPUT] 
      REAL*8       GDO ( IJDIM, KMAXS ) !! sigma level
*   [INPUT] 
      REAL*8       GDPS( IJDIM )
      REAL*8       GDI ( IJDIM, KMAXP ) !! p level
      REAL*8       PLI ( KMAXP )
      REAL*8       SLI ( KMAXS )
      LOGICAL    OMISB
      LOGICAL    OMIST
      REAL*8       XMISS
      DATA       OMISB / .FALSE. /
      DATA       OMIST / .FALSE. /
*
*   [INTERNAL WORK] 
      INTEGER    KMAXD
      PARAMETER  ( KMAXD = 100 )
      REAL*8       PILN ( KMAXD )
      REAL*8       POLN ( KMAXD )
      REAL*8       GDIZ ( KMAXD )
      REAL*8       GDOZ ( KMAXD )
      INTEGER    IJ, KI, KO
*
      DO 1000 KI = 1, KMAXP
         PILN( KI ) = LOG( PLI( KI ) )
 1000 CONTINUE 

      DO 2000 IJ = 1, IJDIM
         DO 2010 KI = 1, KMAXP
            GDIZ(KI) = GDI(IJ,KI)
 2010    CONTINUE 
         DO 2020 KO = 1, KMAXS
            POLN(KO) = LOG( GDPS(IJ)*SLI(KO) )
 2020    CONTINUE
         CALL SPLINE
     O        ( GDOZ,
     I                 POLN,  KMAXS,
     I          GDIZ,  PILN,  KMAXP,
     I          OMISB, OMIST, XMISS  )
         DO 2100 KO = 1, KMAXS
            GDO(IJ,KO) = GDOZ(KO)
 2100    CONTINUE 
 2000 CONTINUE
*
      RETURN
      END
*********************************************************************
      SUBROUTINE SPLINE
     O         ( ZI   ,
     I                  XI   , LMAX ,
     I           Z    , X    , KMAX , 
     I           OMISB, OMIST, XMISS  )
*
      INTEGER    LMAX, KMAX
      REAL*8       ZI  ( LMAX )
      REAL*8       XI  ( LMAX )
      REAL*8       Z   ( KMAX )
      REAL*8       X   ( KMAX )
      LOGICAL    OMISB
      LOGICAL    OMIST
      REAL*8       XMISS

*   [INTERNAL WORK] 
      INTEGER    KMAXD
      PARAMETER  ( KMAXD = 1024 )
      REAL*8       Y2  ( KMAXD )
      REAL*8       U   ( KMAXD )
      REAL*8       SIG, P, QN, UN, H, A, B 
      INTEGER    K, L, KU
*
      IF ( KMAX .GT. KMAXD ) THEN
         WRITE (6,*) ' ### KMAXD IS TOO SMALL ', KMAXD, KMAX
         STOP
      ENDIF
*
      Y2(1)=0.
      U (1)=0.
      DO 120 K=2, KMAX-1
         SIG   = (X(K)-X(K-1))/(X(K+1)-X(K-1))
         P     = SIG*Y2(K-1)+2.
         Y2(K) = (SIG-1.)/P
         U (K) = (6.*( (Z(K+1)-Z(K))/(X(K+1)-X(K))
     &                -(Z(K)-Z(K-1))/(X(K)-X(K-1)))
     &              /(X(K+1)-X(K-1))
     &             - SIG*U(K-1)                     )/P
  120 CONTINUE
      QN = 0.
      UN = 0.
      Y2(KMAX) = (UN-QN*U(KMAX-1))/(QN*Y2(KMAX-1)+1.)
      DO 130 K= KMAX-1, 1, -1
         Y2(K) = Y2(K)*Y2(K+1)+U(K)
  130 CONTINUE
*
      DO 500 L = 1, LMAX
         KU = 1
         DO 300 K = 1, KMAX
            IF( X(K) .LT. XI(L) ) THEN
               KU = K
               GOTO 310
            ENDIF
  300    CONTINUE
         KU = KMAX+1
  310    CONTINUE
*
         IF      ( KU .EQ. 1 ) THEN
            IF ( OMISB ) THEN
               ZI(L) = XMISS
            ELSE
               ZI(L) = Z(1)
            ENDIF
         ELSE IF ( KU .EQ. KMAX+1 ) THEN
            IF ( OMIST ) THEN
               ZI(L) = XMISS
            ELSE
               ZI(L) = Z(KMAX)
            ENDIF            
         ELSE
            KU   = MAX(KU,2)
            H    = X(KU)-X(KU-1)
            A    = (X(KU)-XI(L))/H
            B    = (XI(L)-X(KU-1))/H
            ZI(L)= A*Z(KU-1)+B*Z(KU)
     &           + (A*(A*A-1)*Y2(KU-1)+B*(B*B-1)*Y2(KU))*(H*H)/6.
         ENDIF
  500 CONTINUE
*
      RETURN
      END
