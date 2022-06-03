help([[
]])

load("cmake/3.22.0")
load("python/3.7.9")
load("ncarenv/1.3")
load("gnu/10.1.0")
load("ncarcompilers/0.5.0")
unload("netcdf")

prepend_path("MODULEPATH", "/glade/work/epicufsrt/GMTB/tools/gnu/10.1.0/hpc-stack-v1.2.0/modulefiles/stack")

load("hpc/1.2.0")
load("hpc-gnu/10.1.0")

load("common")

whatis("Description: GSI Monitoring environment on Cheyenne with GNU Compilers")
