help([[
]])

prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.9.1/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")
prepend_path("MODULEPATH", "/apps/modules/modulefiles")

local gcc_ver=os.getenv("gcc_ver") or "13.2.0"
local stack_oneapi_ver=os.getenv("stack_oneapi_ver") or "2024.2.1"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.13"
local grads_ver=os.getenv("grads_ver") or "2.2.3"
local prod_util_ver=os.getenv("prod_util_ver") or "2.1.1"

load(pathJoin("stack-oneapi", stack_oneapi_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
load(pathJoin("grads", grads_ver))
load(pathJoin("prod_util", prod_util_ver))

load("common-run")

whatis("Description: GSI Monitoring run-time environment on NOAA Cloud Intel compiler")
