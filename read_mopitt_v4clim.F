c==============================================================================
c==============================================================================
c
c NAME:
c       READ_MOPITT_V4CLIM
c
c PURPOSE:
c       A routine to read mopitt v4 climatology and save to a file. This was
c       was modified from a reader module within NUCAPS of the same name. Other
c       input files exist, but this repository has the most recent one at the time
c       that the program was writter. [RBE]
c
c MODIFICATION HISTORY:
c       Written by:     Eric Maddy (09/15/2009)
c       Updated by:     Rebekah Esmaili (12/16/2019
c
c  Note: Needs to be in BIG ENDIAN: gfortran -fconvert=big-endian read_mopitt_v4clim.F [RBE]
c==============================================================================
c==============================================================================
c
      PROGRAM READ_MOPITT_V4CLIM
      implicit none

      INTEGER*4 mopitt_clim_npres, mopitt_clim_nlat,
     $     mopitt_clim_nlon, mopitt_clim_nmonth

      INTEGER*4 mopitt_clim_maxtime,
     $     mopitt_clim_maxlon, mopitt_clim_maxlat,
     $     mopitt_clim_maxpres
      PARAMETER (mopitt_clim_maxtime = 12)
      PARAMETER (mopitt_clim_maxlon  = 128)
      PARAMETER (mopitt_clim_maxlat  = 64)
      PARAMETER (mopitt_clim_maxpres = 100)
      REAL*4    mopitt_clim_co(mopitt_clim_maxtime,
     $     mopitt_clim_maxlon, mopitt_clim_maxlat,
     $     mopitt_clim_maxpres), avg_profile_co(mopitt_clim_maxpres),
     $     avg_profile_num(mopitt_clim_maxpres)
      REAL*4    mopitt_clim_pres(mopitt_clim_maxpres)
      REAL*4    mopitt_clim_version
      INTEGER*4 iounit, iret
      CHARACTER*100 c80

c     local variables
c     -------------------------------
      INTEGER*4 nrec, irec, i, nread
      REAL*4    buffer(mopitt_clim_maxpres), buffer5(5)
      INTEGER*4 imonth, ipres, ilon, ilat, ierr

      iret = 0
      iounit = 100
      c80 = './mopitt_v4clim_nhsh_20180605.dat'

c     open the file and read the header to get sizes of arrays
c     --------------------------------------------------------
      OPEN( iounit, FILE=c80, FORM='unformatted',
     $      ACCESS='direct', RECL=20, STATUS='old', IOSTAT=ierr)

      IF (ierr.ne.0) THEN
         WRITE(*,*) "ERROR! Exit @ ln 77"
         stop
      ENDIF

      READ( iounit, REC=1, ERR=1900 ) buffer5

      mopitt_clim_version = buffer5(1)
      mopitt_clim_npres   = INT(buffer5(2))
      mopitt_clim_nlat    = INT(buffer5(3))
      mopitt_clim_nlon    = INT(buffer5(4))
      mopitt_clim_nmonth  = INT(buffer5(5))

      CLOSE(iounit)

      nrec = AMAX0(mopitt_clim_maxlat,mopitt_clim_npres)*4
      nread = AMAX0(mopitt_clim_maxlat,mopitt_clim_npres)

c     re-open the file
c     -------------------
      OPEN( iounit, FILE=c80, FORM='unformatted',
     $     ACCESS='direct',RECL=nrec,STATUS='old', iostat=ierr)

      IF (ierr.ne.0) THEN
        WRITE(*,*) "ERROR! Exit @ ln 100"
        stop
      ENDIF

c     read header 1
c     -------------------
      irec = 1
      READ(iounit, REC=irec, ERR=1900)
     $     (buffer(i), i=1,nread)

c     read header 2
c     -------------------
      irec = irec + 1
      READ(iounit, REC=irec, ERR=1900)
     $     (buffer(i), i=1,nread)

c     read pressure array
c     -------------------
      irec = irec + 1
      READ(iounit, REC=irec, ERR=1900)
     $     (buffer(i), i=1,nread)

      DO ipres = 1, mopitt_clim_npres
         mopitt_clim_pres(ipres) = buffer(ipres)
      ENDDO
      irec = irec + 1

c     read the monthly, lat/lon, climatology for each pressure
c     --------------------------------------------------------

      avg_profile_co(:) =  0.0
      avg_profile_num(:) = 0.0

      DO imonth = 1,mopitt_clim_nmonth
        DO ilon = 1, mopitt_clim_nlon
          DO ipres = 1, mopitt_clim_npres

            READ(iounit, REC=irec, ERR=1900)
     $            (buffer(i), i=1,nread)

            DO ilat = 1, mopitt_clim_nlat

              mopitt_clim_co(imonth, ilon, ilat, ipres) =
     $              buffer(ilat)

              avg_profile_co(ipres)=avg_profile_co(ipres)+buffer(ilat)
              avg_profile_num(ipres)=avg_profile_num(ipres)+1


            ENDDO
            irec = irec + 1
          ENDDO ! loop over pressure
        ENDDO  ! loop over latitude
      ENDDO  ! loop over month

      close(iounit)

c     Save file in a human readable format
c     --------------------------------------------------------

      OPEN(UNIT=1, FILE='./climatology_co.txt', STATUS='REPLACE')
      DO ipres = 1, mopitt_clim_npres
        write(unit=1,fmt=*) mopitt_clim_pres(ipres),
     $    avg_profile_co(ipres)/avg_profile_num(ipres)

      ENDDO

      goto 2000

 1900 iret=-1
 2000 RETURN
      END
