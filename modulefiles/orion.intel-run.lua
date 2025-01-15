help([[
]])

-- Spack Stack installation specs
local ss_dir="/work/noaa/epic/role-epic/spack-stack/orion"
local ss_ver=os.getenv("stack_ver") or "1.6.0"
local ss_env=os.getenv("stack_env") or "gsi-addon-env-rocky9"

prepend_path("MODULEPATH", pathJoin(ss_dir, "spack-stack-" .. ss_ver, "envs", ss_env, "install/modulefiles/Core"))

local stack_intel_ver=os.getenv("stack_intel_ver") or "2021.9.0"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.9.0"
local grads_ver=os.getenv("grads_ver") or "2.2.1"
local prod_util_ver=os.getenv("prod_util_ver") or "2.1.1"

load(pathJoin("stack-intel", stack_intel_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
load(pathJoin("grads", grads_ver))
load(pathJoin("prod_util", prod_util_ver))

load("common-run")

whatis("Description: GSI Monitoring run-time environment on Orion")
