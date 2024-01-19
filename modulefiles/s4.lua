help([[
]])

prepend_path("MODULEPATH", "/data/prod/jedi/spack-stack/spack-stack-1.6.0/envs/gsi-addon-dev/install/modulefiles/Core")

load("license_intel/S4")

local stack_intel_ver=os.getenv("stack_intel_ver") or "2021.5.0"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.5.0"
local cmake_ver=os.getenv("cmake_ver") or "3.23.1"

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
load(pathJoin("cmake", cmake_ver))

load("common")

whatis("Description: GSI Monitoring environment on S4 with Intel Compilers")
