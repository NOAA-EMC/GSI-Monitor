help([[
]])

prepend_path("MODULEPATH", "/contrib/spack-stack/spack-stack-1.9.2/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")

local stack_oneapi_ver=os.getenv("stack_oneapi_ver") or "2024.2.1"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.13"

load(pathJoin("stack-oneapi", stack_oneapi_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))

load("common")

whatis("Description: GSI Monitoring environment on Hera with oneapi Compilers")
