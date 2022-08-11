help([[
]])

prepend_path("MODULEPATH", "/apps/contrib/NCEP/libs/hpc-stack/modulefiles/stack")

local hpc_ver=os.getenv("hpc_ver") or "1.1.0"
local hpc_intel_ver=os.getenv("hpc_intel_ver") or "2018.4"
local grads_ver=os.getenv("grads_ver") or "2.2.1"

load(pathJoin("hpc", hpc_ver))
load(pathJoin("hpc-intel", hpc_intel_ver))
load(pathJoin("grads", grads_ver))

load("common-run")

whatis("Description: GSI Monitoring run-time environment on Orion")
