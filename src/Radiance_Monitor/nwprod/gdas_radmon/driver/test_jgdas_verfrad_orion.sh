#!/bin/ksh

#SBATCH -o gdas_verfrad.o%j
#SBATCH -J gdas_verfrad
#SBATCH --ntasks=1 --mem=5g
#SBATCH --time=20
#SBATCH --account=da-cpu
#SBATCH -D .


set -x

export MY_MACHINE=hera

#export PDATE=${PDATE:-2021022518}	#binary
export PDATE=${PDATE:-2022050318}	#NetCDF

#############################################################
# Specify whether the run is production or development
#############################################################
export PDY=`echo $PDATE | cut -c1-8`
export cyc=`echo $PDATE | cut -c9-10`
export job=gdas_verfrad.${cyc}
export pid=${pid:-$$}
export jobid=${job}.${pid}
export envir=para
export DATAROOT=${DATAROOT:-/work/noaa/da/Edward.Safford/test_data}
export COMROOT=${COMROOT:-/work2/noaa/stmp/esafford/com}


#############################################################
# Specify versions
#############################################################
export gdas_ver=v14.1.0
export global_shared_ver=v14.1.0


#############################################################
# Set user specific variables
#############################################################

export RADMON_SUFFIX=${RADMON_SUFFIX:-testrad}
export NWTEST=${NWTEST:-/work/noaa/da/Edward.Safford/GSI-monitor/src/Radiance_Monitor/nwprod}
export jlogfile=jlogfile.${PDATE}

export HOMEgdas=${HOMEgdas:-${NWTEST}/gdas_radmon}
export HOMEgfs=$HOMEgdas
export FIXgdas=${HOMEgdas}/fix
export EXECradmon=/work/noaa/da/Edward.Safford/GSI-monitor/install/bin

export JOBGLOBAL=${JOBGLOBAL:-${HOMEgdas}/jobs}
export HOMEradmon=${HOMEradmon:-${NWTEST}/radmon_shared}
export COM_IN=${COM_IN:-${DATAROOT}}
export TANKverf=${TANKverf:-${COMROOT}/${RADMON_SUFFIX}}

export SUB=${SUB:-/apps/slurm/default/bin/sbatch}
export NDATE=${NDATE:-/apps/contrib/NCEP/libs/hpc-stack/intel-2020.2/prod_util/1.2.2/bin/ndate}

export parm_file=${HOMEgdas}/parm/gdas_radmon.parm


prevday=`$NDATE -24 $PDATE`
export PDYm1=`echo $prevday | cut -c1-8`
						
#export PATH="$PATH:/scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/intel-18.0.5.274/prod_util/1.2.2/bin"	

#############################################################
# Execute job
#
$JOBGLOBAL/JGDAS_ATMOS_VERFRAD

exit

