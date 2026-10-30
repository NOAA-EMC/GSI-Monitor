#!/bin/bash

#------------------------------------------------------------------------
# find_last_cycle_rgnl.sh
#
#   Determine the last cycle time for which there is data for regional
#   data sources.
#
#   This supports radmon and conmon data which for regional sources is
#   stored in a directory structure like this:
#       $tankdir/$net/$monitor.yyyymmdd/file_name.yyyymmddhh.gz
#
#   If successful, the latest yyyymmddhh timestamp is echoed out.
#------------------------------------------------------------------------

#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo " "
  echo " "
  echo "Usage:  find_last_cycle_rgnl.sh -n|--net net -m|--mon monitor -t|--tank"
  echo " "
  echo "            -n | --net  Name of this data source (e.g. rrfs, nam)"
  echo " "
  echo "            -m | --mon  Monitor name (radmon|conmon)"
  echo " "
  echo "            -t | --tank Path to stored data"
  echo " "
}


#---------------------------------------------------------
#  Set default values and process command line arguments.
#
net=""
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
      -t|--tank)
         tankdir="$2"
         shift # past argument
      ;;
   esac

   shift
done

if [[ -z ${net} ]]; then
  echo "find_last_cycle_rgnl.sh ERROR:  net value was not set."
  usage
  exit 1
fi

if [[ -z ${monitor} ]]; then
  echo "find_last_cycle_rgnl.sh ERROR:  monitor value was not set."
  usage
  exit 1
fi

if [[ -z ${tankdir} ]]; then
  echo "find_last_cycle_rgnl.sh ERROR:  tankdir value was not set."
  usage
  exit 1
fi

# Find the latest subdirectory matching the pattern
latest_dir=$(printf '%s\n' ${tankdir}/${monitor}.[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]/ | sort | tail -n 1)

# Remove trailing slash
latest_dir=${latest_dir%/}

if [[ ${monitor} = "conmon" ]]; then
   latest_datetime=$(ls "${latest_dir}"/time_vert/*.[0-9]*.gz | sort | tail -n 1 | grep -oE '[0-9]{10}')
else
   latest_datetime=$(ls "${latest_dir}"/*.[0-9]*.gz | sort | tail -n 1 | grep -oE '[0-9]{10}')
fi

echo ${latest_datetime}
