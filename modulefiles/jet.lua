help([[
]])

load("cmake/3.20.1")

prepend_path("MODULEPATH", "/contrib/anaconda/modulefiles")

prepend_path("MODULEPATH", "/lfs4/HFIP/hfv3gfs/nwprod/hpc-stack/libs/modulefiles/stack")

load("hpc/1.1.0")
load("hpc-intel/18.0.5.274")

load("common")

whatis("Description: GSI Monitoring environment on Jet with Intel Compilers")
