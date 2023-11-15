help([[
]])

prepend_path("MODULEPATH", "/mnt/lfs4/HFIP/hfv3gfs/role.epic/spack-stack/spack-stack-1.5.1/envs/gsi-addon/install/modulefiles/Core")

local stack_python_ver=os.getenv("stack_python_ver") or "3.10.8"
local stack_intel_ver=os.getenv("stack_intel_ver") or "2021.5.0"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.5.1"
local cmake_ver=os.getenv("cmake_ver") or "3.23.1"

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
load(pathJoin("stack-python", stack_python_ver))
load(pathJoin("cmake", cmake_ver))

load("common")

whatis("Description: GSI Monitoring environment on Jet with Intel Compilers")
