#!/bin/bash

#------------------------------------------------------------------
#
#  clean_tankdir_rgn.sh
#
#------------------------------------------------------------------

   older_than=30

   #-----------------------------------------------
   #  Get list of conmon directories in $C_TANKDIR
   #
   dirs=`ls ${C_TANKDIR} | grep conmon`

   #----------------------------------------------- 
   #  Determine number of days from $PDATE for all 
   #  directories. 
   #
   for dir in $dirs; do
      file_name="${dir##*/}"
      dir_extension="${file_name##*.}"

      #--------------------------------------------------
      # Determine number of days from $PDATE.  Note
      # that time difference is calculated in seconds, 
      # hence the division by the number of seconds/day.
      #
      days=$(( ($(date --date=${PDY} +%s) - $(date --date=${dir_extension} +%s) )/(60*60*24) ))

      if [ $days -gt ${older_than} ]; then
         echo "removing ${C_TANKDIR}/${dir}"
         rm -rf ${C_TANKDIR}/${dir}
      fi
   done

exit 

