help([[
]])

prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/spack-stack-1.6.0/envs/unified-env/install/modulefiles/Core")

local stack_intel_ver=os.getenv("stack_intel_ver") or "2023.1.0"
local stack_cray_mpich_ver=os.getenv("stack_cray_mpich_ver") or "8.1.25"
local grads_ver=os.getenv("grads_ver") or "2.0.2"
local prod_util_ver=os.getenv("prod_util_ver") or "2.1.1"

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-cray-mpich", stack_cray_mpich_ver))
load(pathJoin("grads", grads_ver))
load(pathJoin("prod_util", prod_util_ver))

load("common-run")

whatis("Description: GSI Monitoring run-time environment on Hera.intel")
