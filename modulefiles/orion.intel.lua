help([[
]])

-- Spack Stack installation specs
prepend_path("MODULEPATH", "/apps/contrib/spack-stack/spack-stack-1.9.1/envs/ue-oneapi-2024.1.0/install/modulefiles/Core")

local stack_oneapi_ver=os.getenv("stack_oneapi_ver") or "2024.2.1"
local stack_intel_oneapi_mpi=os.getenv("stack_intel_oneapi_mpi") or "2021.13"
local cmake_ver=os.getenv("cmake_ver") or "3.26.3"

load(pathJoin("stack-oneapi", stack_oneapi_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi))
load(pathJoin("cmake", cmake_ver))

setenv("netcdf_fortran_ver", "4.6.0")

load("common")

whatis("Description: GSI Monitoring environment on Orion with Intel Compilers")
