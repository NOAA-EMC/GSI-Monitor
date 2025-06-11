help([[
]])

prepend_path("MODULEPATH", "/ncrc/proj/epic/spack-stack/c6/spack-stack-1.9.1/envs/ue-intel-2023.2.0/install/modulefiles/Core")

local stack_intel_ver=os.getenv("stack_intel_ver") or "2023.2.0"
local stack_cray_mpich_ver=os.getenv("stack_cray_mpich_ver") or "8.1.30"
local Core_ver=os.getenv("Core_ver") or "24.11"
local grads_ver=os.getenv("grads_ver") or "2.2.3"

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-cray-mpich", stack_cray_mpich_ver))
-- The Core module add modules that were populated following a system upgrade in November 2024 (including GrADS)
load(pathJoin("Core", Core_ver))
load(pathJoin("grads", grads_ver))

load("common-run")

whatis("Description: GSI Monitoring run-time environment on GaeaC6.intel")
