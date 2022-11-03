#!/bin/bash

#------------------------------------------------------------------------
# find_last_cycle.sh
#
#   Test the common options for monitor data storage ($tankdir/stats),
#   then determine the last cycle time for which there is data.  The
#   last cycle time will be echoed to stdout. 
#
#   OznMon and MinMon output is supported.  Support for RadMon and 
#   ConMon will be added soon.
#
#   Extracted DA monitor data files are stored in a directory identified 
#   as $tankdir, however there are 3 common directory structures in use.
#   This script handles all 3.
#
#   The supported directory structures are:
#      Operations:  $tankdir/$net/version/$run.$pdy/$hh/atmos/$monitor
#      Workflow  :  $tankdir/$monitor/stats/$net/$run.$pdy/$hh
#      Monitors* :  $tankdir/stats/$net/$run.$pdy/$hh/$monitor
#
#   The get_stats_path.sh script will be used to find a valid path from 
#   $tankdir to the directory above $run.$pdy (which, conveniently, is
#   common to all cases). 
#
#
#   * This used to be the operations format, now used internally in 
#      the DA monitors via the copy scripts. 
#------------------------------------------------------------------------


#---------------------------------------------------------
#  Set default values and process command line arguments.
#
net=""
run=gdas
tankdir=""
monitor=""

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
      -r|--run)
         run="$2"
         shift # past argument
      ;;
      -t|--tank)
         tankdir="$2"
         shift # past argument
      ;;
   esac

   shift
done


#-----------------------------------------
# Call get_stats_path to extend $tankdir
#
path=`${MON_USH}/get_stats_path.sh --net ${net} --run ${run} --tank ${tankdir} --mon ${monitor} --rpath base`

if [[ ${#path} -gt 0 ]]; then

   hrs="18 12 06 00"
  
   #--------------------------------------------------------------- 
   #  Get list of reverse sorted subdirs which is in the form of 
   #  $run.$pdy in all cases.  Then step through the possible 
   #  options for ops, wkfl, and mon, halting when the first valid 
   #  output files are found.
   #
   flist=`find "${path}" -maxdepth 1 -mindepth 1 -type d -name "${run}.*" -printf "%f\n" 2>/dev/null`
   sorted=`echo ${flist[@]} | awk 'BEGIN{RS=" ";} {print $1}' | sort -r`

   lcyc=""
   for file in $sorted; do

      for hr in $hrs; do

         mon_test=`find "${path}/${file}/${hr}/${monitor}" -maxdepth 2 -mindepth 1 -name "*.ieee_d" -printf "%f\n" 2>/dev/null`
         wkfl_test=`find "${path}/${file}/${hr}/" -maxdepth 2 -mindepth 1 -name "*.ieee_d" -printf "%f\n" 2>/dev/null`
         ops_test=`find "${path}/${file}/${hr}/atmos/${monitor}" -maxdepth 2 -mindepth 1 -name "*.ieee_d" -printf "%f\n" 2>/dev/null`

         if [[ ${#mon_test} -gt 0 || ${#ops_test} -gt 0 || ${#wkfl_test} -gt 0 ]]; then
            lcyc=`echo $file | gawk -F. '{print $2}'`
            lcyc="${lcyc}${hr}"
            echo "$lcyc"
            break
         fi

      done

      if [[ ${#lcyc} -gt 0 ]]; then
         break
      fi
   done
   
fi
