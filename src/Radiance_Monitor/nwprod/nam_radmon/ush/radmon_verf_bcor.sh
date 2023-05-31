#!/bin/bash

export PDATE=${1:-${PDATE:?}}

if [[ "$VERBOSE" = "YES" ]]; then
   set -ax
fi

# Directories
EXECradmon=${EXECradmon:-$(pwd)}
TANKverf_rad=${TANKverf_rad:-$(pwd)}

# File names
pgmout=${pgmout:-${jlogfile}}

# Other variables
RAD_AREA=${RAD_AREA:-rgn}
SATYPE=${SATYPE:-}
VERBOSE=${VERBOSE:-NO}
USE_ANL=${USE_ANL:-0}

bcor_exec=radmon_bcor.x
err=0

netcdf_boolean=".false."
if [[ $RADMON_NETCDF -eq 1 ]]; then
   netcdf_boolean=".true."
fi

if [[ $USE_ANL -eq 1 ]]; then
   gesanl="ges anl"
else
   gesanl="ges"
fi


#--------------------------------------------------------------------
#   Copy extraction program to working directory

$NCP ${GSI_MON_BIN}/${bcor_exec}  ./${bcor_exec}

if [[ ! -s ./${bcor_exec} ]]; then
   err=6
else


#--------------------------------------------------------------------
#   Run program for given time

   export pgm=${bcor_exec}

   iyy=`echo $PDATE | cut -c1-4`
   imm=`echo $PDATE | cut -c5-6`
   idd=`echo $PDATE | cut -c7-8`
   ihh=`echo $PDATE | cut -c9-10`

   ctr=0
   fail=0
#   touch "./errfile"

   for type in ${SATYPE}; do

      for dtype in ${gesanl}; do

         ctr=`expr $ctr + 1`

         if [[ $dtype == "anl" ]]; then
            data_file=${type}_anl.${PDATE}.ieee_d
            bcor_file=bcor.${data_file}
            ctl_file=${type}_anl.ctl
            bcor_ctl=bcor.${ctl_file}
            stdout_file=stdout.${type}_anl
            bcor_stdout=bcor.${stdout_file}
            input_file=${type}_anl
         else
            data_file=${type}.${PDATE}.ieee_d
            bcor_file=bcor.${data_file}
            ctl_file=${type}.ctl
            bcor_ctl=bcor.${ctl_file}
            stdout_file=stdout.${type}
            bcor_stdout=bcor.${stdout_file}
            input_file=${type}
         fi

         if [[ -e ./input ]]; then
             rm ./input
         fi

      # Check for 0 length input file here and avoid running 
      # the executable if $input_file doesn't exist or is 0 bytes
      #
         if [[ -s $input_file ]]; then
            nchanl=-999

cat << EOF > input
 &INPUT
  satname='${type}',
  iyy=${iyy},
  imm=${imm},
  idd=${idd},
  ihh=${ihh},
  idhh=-720,
  incr=6,
  nchanl=${nchanl},
  suffix='${RADMON_SUFFIX}',
  gesanl='${dtype}',
  little_endian=${LITTLE_ENDIAN},
  rad_area='${RAD_AREA}',
  netcdf=${netcdf_boolean},
 /
EOF
   
            ./${bcor_exec} < input >> stdout.${type} 2>>errfile
#            export err=$?; err_chk
            if [[ $? -ne 0 ]]; then
               fail=`expr $fail + 1`
            fi
 

#-------------------------------------------------------------------
#  move data, control, and stdout files to $TANKverf_rad and compress
#
            cat stdout.${type} >> stdout.bcor
            rm stdout.${type}
 
            if [[ -s ${bcor_file} ]]; then
               ${COMPRESS} ${bcor_file}
            fi

            if [[ -s ${bcor_ctl} ]]; then
               ${COMPRESS} ${bcor_ctl}
            fi

         fi
      done  # dtype in $gesanl loop
   done     # type in $SATYPE loop


   ${USHradmon}/rstprod.sh
   tar_file=radmon_bcor.tar

   tar -cf $tar_file bcor*.ieee_d* bcor*.ctl*
   ${COMPRESS} ${tar_file}
   mv $tar_file.${Z} ${TANKverf_rad}/.

   if [[ $RAD_AREA = "rgn" ]]; then
      cwd=`pwd`
      cd ${TANKverf_rad}
      tar -xf ${tar_file}.${Z}
      rm ${tar_file}.${Z}
      cd ${cwd}
   fi

   if [[ $fail -eq $ctr || $fail -gt $ctr ]]; then
      err=7
   fi
fi

################################################################################
#  Post processing

if [[ "$VERBOSE" = "YES" ]]; then
   echo $(date) EXITING $0 error code ${err} >&2
fi

exit ${err}

