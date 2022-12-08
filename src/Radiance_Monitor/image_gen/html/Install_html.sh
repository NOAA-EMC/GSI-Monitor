#!/bin/bash

#--------------------------------------------------------------------
#--------------------------------------------------------------------
#  Install_html.sh
#
#  Given a suffix and a global/regional flag as inputs, build the
#  html necessary for a radiance monitor web site and tranfer it to
#  the server.
#--------------------------------------------------------------------
#--------------------------------------------------------------------

#--------------------------------------------------------------------
#  usage
#--------------------------------------------------------------------
function usage {
  echo "Usage:  Install_html.sh suffix [-t|--tank]"
  echo "            Suffix is data source identifier that matches data in "
  echo "              the $TANKDIR/stats directory."
  echo "            -t | --tank parent directory to the adnmon data file location.  This"
  echo "              will be extended by \$RADMON_SUFFIX, \$RUN, and \$PDATE to locate the"
  echo "              extracted radmon data."
  echo ""
}

echo "BEGIN Install_html.sh"
echo ""

nargs=$#

if [[ $nargs -lt 1 || $nargs -gt 3 ]]; then
   usage
   exit 2
fi

#-----------------------------------------------------------
#  Set default values and process command line arguments.
#
#run=gdas
tank=""
area=""

while [[ $# -ge 1 ]]; do
   key="$1"

   case $key in
      -t|--tank)
         tank="$2"
	 shift # past argument
         ;;
      *)
         #any unspecified key is RADMON_SUFFIX
	 export RADMON_SUFFIX=$key
	 ;;
   esac
   shift
done

this_file=`basename $0`
this_dir=`dirname $0`

top_parm=${this_dir}/../../parm

radmon_config=${radmon_config:-${top_parm}/RadMon_config}
if [[ ! -e ${radmon_config} ]]; then
   echo "Unable to source ${radmon_config}"
   exit 2
fi

. ${radmon_config}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${radmon_config} file"
   exit $?
fi


radmon_user_settings=${radmon_user_settings:-${top_parm}/RadMon_user_settings}
if [[ ! -e ${radmon_user_settings} ]]; then
   echo "Unable to locate ${radmon_user_settings} file"
   exit 4
fi

. ${radmon_user_settings}
if [[ $? -ne 0 ]]; then
   echo "Error detected while sourcing ${radmon_user_settings} file"
   exit $?
fi


if [[ ${#tank} -le 0 ]]; then
   tank=${TANKDIR}
fi
export R_TANKDIR=${tank}
echo R_TANKDIR = $R_TANKDIR


${RADMON_IMAGE_GEN}/html/install_glb.sh 


echo "END Install_html.sh"

exit
