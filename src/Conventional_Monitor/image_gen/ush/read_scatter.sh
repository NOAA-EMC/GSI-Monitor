#!/bin/bash

#-----------------------------------------------------------------------------------
#
#  read_scatter.sh
#
#    Extract a subset of data from the scater file
#    and generate an out_${mtype) data file and 
#    control file for GrADS.
#-----------------------------------------------------------------------------------
exp=$1
dtype=$2
mtype=$3
subtype=$4
rdate=$5
fixdir=$6
nreal=$7
exec=$8
type=$9
cycle=${10}
datadir=${11}
sorcdir=${12}

## set up the directory with excutable files

fixfile=global_convinfo.txt 
if [[ ! -e ./convinfo ]]; then
   cp ${fixdir}/${fixfile} ./convinfo
fi

fname=$datadir/${dtype}.scater.${cycle}.${rdate}


#-----------------------------------------------------------
#
# Create namelist input file.  
#

rm -f input
cat << EOF > input
  &input 
  nreal=${nreal},
  mtype='${mtype}',
  fname='${fname}',
  fileo='out_${dtype}_${cycle}.${rdate}',
  rlev=0.1,
  insubtype=${subtype},
  grads_info_file='grads_info_${dtype}_${cycle}.${rdate}'
/
EOF

cp $sorcdir/$exec ./$exec

./$exec <input  > stdout_${dtype}_${cycle}.${rdate}  2>&1


if [ "${type}" = 'uv' ]; then
   mv out_u out_${dtype}_u_${cycle}.${rdate}
   mv out_v out_${dtype}_v_${cycle}.${rdate}

   mv stdout_u stdout_${dtype}_u_${cycle}.${rdate}
   mv stdout_v stdout_${dtype}_v_${cycle}.${rdate}

   mv grads_info_u grads_info_${dtype}_u_${cycle}.${rdate}
   mv grads_info_v grads_info_${dtype}_v_${cycle}.${rdate}
fi


exit
