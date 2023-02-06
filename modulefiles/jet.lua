help([[
]])

prepend_path("MODULEPATH", "/lfs4/HFIP/hfv3gfs/role.epic/hpc-stack/libs/intel-18.0.5.274/modulefiles/stack")

local hpc_ver=os.getenv("hpc_ver") or "1.2.0"
local hpc_intel_ver=os.getenv("hpc_intel_ver") or "18.0.5.274"
local hpc_impi_ver=os.getenv("hpc_impi_ver") or "2018.4.274"
local cmake_ver=os.getenv("cmake_ver") or "3.20.1"

load(pathJoin("hpc", hpc_ver))
load(pathJoin("hpc-intel", hpc_intel_ver))
load(pathJoin("hpc-impi", hpc_impi_ver))
load(pathJoin("cmake", cmake_ver))

load("common")

whatis("Description: GSI Monitoring environment on Jet with Intel Compilers")
