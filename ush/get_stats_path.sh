#!/bin/bash

#---------------------------------------------------------------------
# get_stats_path.sh
#
#   Test the common options for monitor data storage ($tankdir/stats)
#   and return a valid path per the parameters or nothing if no
#   directory is found.
#
#   Over time the default paths for extracted DA monitor data
#   for operations and workflow (global-workflow and 
#   rocoto) have diverged.  This script checks each of the 3 
#   possible data locations (ops, workflow, monitor) for the input
#   parameters.
#
#---------------------------------------------------------------------


#-----------------------------------------------------------------
#  Set default values and process command line arguments.
#
net=gfs
run=gdas
tankdir=""
pdate=""
version="v16.3"
monitor=""
rtn_path="full"		# options are full or base

while [[ $# -ge 1 ]]
do
   key="$1"

   case $key in
      -m|--mon)
         monitor="$2"
         shift # past argument
      ;;
      -n|--net)
         net="$2"
         shift # past argument
      ;;
      -p|--pdate)
         pdate="$2"
         shift # past argument
      ;;
      -r|--run)
         run="$2"
         shift # past argument
      ;;
      -t|--tank)
         tankdir="$2"
         shift # past argument
      ;;
      -v|--ver)
         version="$2"
         shift # past argument
      ;;
      --rpath)
         rtn_path="$2"
         shift # past argument
      ;;
 
   esac

   shift
done

pdy=""; hh=""
if [[ ${#pdate} -gt 0 ]]; then
   pdy=`echo ${pdate} | cut -c1-8`
   hh=`echo ${pdate} | cut -c9-10`
fi


#------------------------------
# Possible data storage paths
#
ops_base=${tankdir}/${net}/${version}
ops_xtn=${run}.${pdy}/${hh}/atmos/${monitor}
ops=${ops_base}/${ops_xtn}

wkf_base=${tankdir}/${net}
wkf_xtn=${run}.${pdy}/${hh}/products/atmos/${monitor}
wkf=${wkf_base}/${wkf_xtn}

mon_base=${tankdir}/stats/${net}
mon_xtn=${run}.${pdy}/${hh}/${monitor}
mon=${mon_base}/${mon_xtn}


case ${rtn_path} in

   full)
      if [[ -d ${ops} ]]; then
         echo ${ops}
      elif [[ -d ${wkf} ]]; then
         echo ${wkf}
      elif [[ -d ${mon} ]]; then
         echo ${mon}
      fi
      ;;

   base)
      if [[ -d ${ops_base} ]]; then
         echo ${ops_base}
      elif [[ -d ${wkf_base} ]]; then
         echo ${wkf_base}
      elif [[ -d ${mon_base} ]]; then
         echo ${mon_base}
      fi
      ;;
esac

