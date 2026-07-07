help([[
]])

-- Spack Stack installation specs
prepend_path("MODULEPATH", "/contrib/spack-stack/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")

local stack_oneapi_ver=os.getenv("stack_oneapi_ver") or "2024.2.1"
local stack_intel_oneapi_mpi_ver=os.getenv("stack_intel_oneapi_mpi_ver") or "2021.13"

local grads_ver=os.getenv("grads_ver") or "2.2.3"
local tar_ver=os.getenv("tar_ver") or "1.34"

load(pathJoin("stack-oneapi", stack_oneapi_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_intel_oneapi_mpi_ver))

load(pathJoin("grads", grads_ver))
load(pathJoin("tar", tar_ver))

load("common-run")

whatis("Description: GSI Monitoring run-time environment on Ursa")
