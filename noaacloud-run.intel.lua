help([[
]])

prepend_path("MODULEPATH", "/contrib/spack-stack-rocky8/spack-stack-1.6.0/envs/gsi-addon-env/install/modulefiles/Core")
prepend_path("MODULEPATH", "/apps/modules/modulefiles")

local stack_intel_ver=os.getenv("stack_intel_ver") or "2021.10.0"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.10.0"

load("gnu")
load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
unload("gnu")

local grads_ver=os.getenv("grads_ver") or "2.2.3"
local prod_util_ver=os.getenv("prod_util_ver") or "2.1.1"

load("common-run")

whatis("Description: GSI Monitoring run-time environment on NOAA Cloud Intel compiler")
