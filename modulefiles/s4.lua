help([[
]])

local hpc_ver=os.getenv("hpc_ver") or "1.1.0"
local hpc_intel_ver=os.getenv("hpc_intel_ver") or "18.0.4"

prepend_path("MODULEPATH", "/data/prod/hpc-stack/modulefiles/stack")

load("license_intel/S4")
load(pathJoin("hpc", hpc_ver))
load(pathJoin("hpc-intel", hpc_intel_ver))

load("common")

whatis("Description: GSI Monitoring environment on S4 with Intel Compilers")
