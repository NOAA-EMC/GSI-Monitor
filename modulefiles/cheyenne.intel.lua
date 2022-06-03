help([[
]])

load("cmake/3.22.0")
load("python/3.7.9")
load("ncarenv/1.3")
load("intel/2022.1")
load("ncarcompilers/0.5.0")

prepend_path("MODULEPATH", "/glade/work/epicufsrt/GMTB/tools/intel/2022.1/hpc-stack-v1.2.0_6eb6/modulefiles/stack")

load("hpc/1.2.0")
load("hpc-intel/2022.1")

load("common")

whatis("Description: GSI Monitoring environment on Cheyenne with Intel Compilers")
