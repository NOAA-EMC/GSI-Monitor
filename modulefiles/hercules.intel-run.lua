help([[
]])

prepend_path("MODULEPATH", "/work/noaa/epic/role-epic/spack-stack/hercules/spack-stack-1.6.0/envs/gsi-addon-env/install/modulefiles/Core")

local stack_intel_ver=os.getenv("stack_intel_ver") or "2021.9.0"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.9.0"
local grads_ver=os.getenv("grads_ver") or "2.2.1"
local prod_util_ver=os.getenv("prod_util_ver") or "1.2.2"

-- wgrib2 is a newer version on Hercules
setenv("wgrib2_ver", "3.1.1")

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
load(pathJoin("grads", grads_ver))
load(pathJoin("prod_util", prod_util_ver))

load("common-run")

whatis("Description: GSI Monitoring run-time environment on Hercules")
