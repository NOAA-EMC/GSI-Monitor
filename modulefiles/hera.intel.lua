help([[
]])

prepend_path("MODULEPATH", "/scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/modulefiles/stack")

local hpc_ver=os.getenv("hpc_ver") or "1.1.0"
local hpc_intel_ver=os.getenv("hpc_intel_ver") or "18.0.5.274"
local cmake_ver=os.getenv("cmake_ver") or "3.20.1"

load(pathJoin("hpc", hpc_ver))
load(pathJoin("hpc-intel", hpc_intel_ver))
load(pathJoin("cmake", cmake_ver))

load("common")

whatis("Description: GSI Monitoring environment on Hera with Intel Compilers")
