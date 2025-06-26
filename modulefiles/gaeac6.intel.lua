help([[
]])

prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/c6/spack-stack-1.9.1/envs/ue-intel-2023.2.0/install/modulefiles/Core")

local stack_intel_ver=os.getenv("stack_intel_ver") or "2023.2.0"
local stack_cray_mpich_ver=os.getenv("stack_cray_mpich_ver") or "8.1.30"

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-cray-mpich", stack_cray_mpich_ver))

load("common")
unload("cray-libsci")

whatis("Description: GSI Monitoring environment on GaeaC6 with Intel Compilers")
