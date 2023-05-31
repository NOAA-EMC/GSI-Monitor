#!/bin/bash

export PDATE=${1:-${PDATE:?}}

netcdf_boolean=".false."
if [[ $RADMON_NETCDF -eq 1 ]]; then
   netcdf_boolean=".true."
fi

if [[ "$VERBOSE" = "YES" ]]; then
   set -ax
fi


# Directories
FIXgdas=${FIXgdas:-$(pwd)}
EXECradmon=${EXECradmon:-$(pwd)}
TANKverf_rad=${TANKverf_rad:-$(pwd)}

# File names
pgmout=${pgmout:-${jlogfile}}
#touch $pgmout

# Other variables
RAD_AREA=${RAD_AREA:-rgn}
REGIONAL_RR=${REGIONAL_RR:-1}
rgnHH=${rgnHH:-}
rgnTM=${rgnTM:-}
SATYPE=${SATYPE:-}
VERBOSE=${VERBOSE:-NO}
#LITTLE_ENDIAN=${LITTLE_ENDIAN:-0}
USE_ANL=${USE_ANL:-0}


err=0
bcoef_exec=radmon_bcoef.x

if [[ $USE_ANL -eq 1 ]]; then
   gesanl="ges anl"
else
   gesanl="ges"
fi

#--------------------------------------------------------------------
#   Copy extraction program and supporting files to working directory

$NCP ${GSI_MON_BIN}/${bcoef_exec}           ./${bcoef_exec}
$NCP ${biascr}                              ./biascr.txt

if [[ ! -s ./${bcoef_exec} || ! -s ./biascr.txt ]]; then
   err=4
else


#--------------------------------------------------------------------
#   Run program for given time

   export pgm=${bcoef_exec}

   iyy=`echo $PDATE | cut -c1-4`
   imm=`echo $PDATE | cut -c5-6`
   idd=`echo $PDATE | cut -c7-8`
   ihh=`echo $PDATE | cut -c9-10`

   ctr=0
   fail=0

   nchanl=-999
   npredr=5

   for type in ${SATYPE}; do

      if [[ ! -s ${type} ]]; then
         echo "ZERO SIZED:  ${type}"
         continue
      fi

      for dtype in ${gesanl}; do

         ctr=`expr $ctr + 1`

         if [[ $dtype == "anl" ]]; then
            data_file=${type}_anl.${PDATE}.ieee_d
            ctl_file=${type}_anl.ctl
            bcoef_ctl=bcoef.${ctl_file}
         else
            data_file=${type}.${PDATE}.ieee_d
            ctl_file=${type}.ctl
            bcoef_ctl=bcoef.${ctl_file}
         fi 

         if [[ $REGIONAL_RR -eq 1 ]]; then
            bcoef_file=${rgnHH}.bcoef.${data_file}.${rgnTM}
         else
            bcoef_file=bcoef.${data_file}
         fi
 
         if [[ -e ./input ]]; then
             rm ./input
         fi

cat << EOF > input
 &INPUT
  satname='${type}',
  npredr=${npredr},
  nchanl=${nchanl},
  iyy=${iyy},
  imm=${imm},
  idd=${idd},
  ihh=${ihh},
  idhh=-720,
  incr=${CYCLE_INTERVAL},
  suffix='${RADMON_SUFFIX}',
  gesanl='${dtype}',
  little_endian=${LITTLE_ENDIAN},
  netcdf=${netcdf_boolean},
 /
EOF
#         startmsg
         ./${bcoef_exec} < input >> stdout.${type} 2>>errfile
#         export err=$?; err_chk
         if [[ $err -ne 0 ]]; then
            fail=`expr $fail + 1`
         fi


#-------------------------------------------------------------------
#  move data, control, and stdout files to $TANKverf_rad and compress
#

         cat stdout.${type} >> stdout.bcoef
         rm stdout.${type}

         if [[ -s ${bcoef_file} ]]; then
            ${COMPRESS} ${bcoef_file}
         fi

         if [[ -s ${bcoef_ctl} ]]; then
            ${COMPRESS} ${bcoef_ctl}
         fi


      done  # dtype in $gesanl loop
   done     # type in $SATYPE loop


   ${USHradmon}/rstprod.sh

   tar_file=radmon_bcoef.tar
   tar -cf $tar_file bcoef*.ieee_d* bcoef*.ctl*
   ${COMPRESS} ${tar_file}
   mv $tar_file.${Z} ${TANKverf_rad}

   if [[ $RAD_AREA = "rgn" ]]; then
      cwd=`pwd`
      cd ${TANKverf_rad}
      tar -xf ${tar_file}.${Z}
      rm ${tar_file}.${Z}
      cd ${cwd}
   fi

   if [[ $fail -eq $ctr || $fail -gt $ctr ]]; then
      err=5
   fi
fi


################################################################################
#  Post processing
if [[ "$VERBOSE" = "YES" ]]; then
   echo $(date) EXITING $0 with error code ${err} >&2
fi


exit ${err}
