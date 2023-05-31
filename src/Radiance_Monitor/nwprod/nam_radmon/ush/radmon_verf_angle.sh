#!/bin/bash

# Command line arguments.
RAD_AREA=${RAD_AREA:-rgn}
REGIONAL_RR=${REGIONAL_RR:-1}	# rapid refresh model flag
rgnHH=${rgnHH:-}
rgnTM=${rgnTM:-}

export PDATE=${1:-${PDATE:?}}

echo " REGIONAL_RR, rgnHH, rgnTM = $REGIONAL_RR, $rgnHH, $rgnTM"
netcdf_boolean=".false."
if [[ $RADMON_NETCDF -eq 1 ]]; then
   netcdf_boolean=".true."
fi  
echo " RADMON_NETCDF, netcdf_boolean = ${RADMON_NETCDF}, $netcdf_boolean"

#if [[ "$VERBOSE" = "YES" ]]; then
#   set -ax
#fi

# Directories
FIXgdas=${FIXgdas:-$(pwd)}
EXECradmon=${EXECradmon:-$(pwd)}
TANKverf_rad=${TANKverf_rad:-$(pwd)}

# File names
pgmout=${pgmout:-${jlogfile}}
#touch $pgmout

# Other variables
SATYPE=${SATYPE:-}
VERBOSE=${VERBOSE:-NO}
#LITTLE_ENDIAN=${LITTLE_ENDIAN:-0}
USE_ANL=${USE_ANL:-0}


if [[ $USE_ANL -eq 1 ]]; then
   gesanl="ges anl"
else
   gesanl="ges"
fi

err=0
angle_exec=radmon_angle.x
shared_scaninfo=${shared_scaninfo:-$FIXgdas/gdas_radmon_scaninfo.txt}
scaninfo=scaninfo.txt

#--------------------------------------------------------------------
#   Copy extraction program and supporting files to working directory

$NCP ${GSI_MON_BIN}/${angle_exec}  ./
$NCP $shared_scaninfo  ./${scaninfo}

if [[ ! -s ./${angle_exec} || ! -s ./${scaninfo} ]]; then
   err=2
else
#--------------------------------------------------------------------
#   Run program for given time

   export pgm=${angle_exec}

   iyy=`echo $PDATE | cut -c1-4`
   imm=`echo $PDATE | cut -c5-6`
   idd=`echo $PDATE | cut -c7-8`
   ihh=`echo $PDATE | cut -c9-10`

   ctr=0
   fail=0
#   touch "./errfile"

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
            angl_ctl=angle.${ctl_file}
         else
            data_file=${type}.${PDATE}.ieee_d
            ctl_file=${type}.ctl
            angl_ctl=angle.${ctl_file}
         fi

         if [[ $REGIONAL_RR -eq 1 ]]; then
            angl_file=${rgnHH}.${data_file}.${rgnTM}
         fi

         if [[ -e ./input ]]; then
             rm ./input
         fi

         nchanl=-999
cat << EOF > input
 &INPUT
  satname='${type}',
  iyy=${iyy},
  imm=${imm},
  idd=${idd},
  ihh=${ihh},
  idhh=-720,
  incr=${CYCLE_INTERVAL},
  nchanl=${nchanl},
  suffix='${RADMON_SUFFIX}',
  gesanl='${dtype}',
  little_endian=${LITTLE_ENDIAN},
  rad_area='${RAD_AREA}',
  netcdf=${netcdf_boolean},
 /
EOF

#	 startmsg
         ./${angle_exec} < input >>   stdout.${type} 2>>errfile
#         export err=$?; err_chk
         if [[ $err -ne 0 ]]; then
             fail=`expr $fail + 1`
         fi
         
#-------------------------------------------------------------------
#  move data, control, and stdout files to $TANKverf_rad and compress
         cat stdout.${type} >> stdout.angle
         rm stdout.${type}

         if [[ -s ${angl_file} ]]; then
            ${COMPRESS} -f ${angl_file}
         fi

         if [[ -s ${angl_ctl} ]]; then
            ${COMPRESS} -f ${angl_ctl}
         fi 


      done    # for dtype in ${gesanl} loop

   done    # for type in ${SATYPE} loop


   ${USHradmon}/rstprod.sh

   echo TANKverf_rad = $TANKverf_rad
   
   tar_file=radmon_angle.tar 
   echo tar_file = $tar_file
   tar -cf $tar_file angle*.ieee_d* angle*.ctl*
   if [[ -e $tar_file ]]; then
      echo tar_file $tar_file exists
   fi

   ${COMPRESS} ${tar_file}
   mv $tar_file.${Z} ${TANKverf_rad}/.
   echo "moving $tar_file"

   if [[ $RAD_AREA = "rgn" ]]; then
      cwd=`pwd`
      cd ${TANKverf_rad}
      tar -xf ${tar_file}.${Z}
      rm ${tar_file}.${Z}
      cd ${cwd}
   fi   

   if [[ $fail -eq $ctr || $fail -gt $ctr ]]; then
      err=3
   fi
fi

################################################################################
#  Post processing

if [[ "$VERBOSE" = "YES" ]]; then
   echo $(date) EXITING $0 error code ${err} >&2
fi


echo "<-- radmon_verf_angle.sh"
exit ${err}
