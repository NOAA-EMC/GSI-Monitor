help([[
]])

prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")
prepend_path("MODULEPATH", "/apps/modules/modulefiles")

local gcc_ver=os.getenv("gcc_ver") or "13.2.0"
local stack_oneapi_ver=os.getenv("stack_oneapi_ver") or "2024.2.1"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.13"

load(pathJoin("gnu", gcc_ver))
load(pathJoin("stack-oneapi", stack_oneapi_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))

load("common")

whatis("Description: GSI Monitoring environment on NOAA Cloud with Intel Compilers")
