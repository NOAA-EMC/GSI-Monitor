help([[
]])

prepend_path("MODULEPATH", "/data/prod/hpc-stack/modulefiles/stack")

local license_ver=os.getenv("license_ver") or "S4"
local hpc_ver=os.getenv("hpc_ver") or "1.1.0"
local hpc_intel_ver=os.getenv("hpc_intel_ver") or "18.0.4"
local hpc_impi_ver=os.getenv("hpc_impi_ver") or "18.0.4"
local grads_ver=os.getenv("grads_ver") or "2.2.1"
local prod_util_ver=os.getenv("prod_util_ver") or "1.2.2"

load(pathJoin("license_intel", license_ver))
load(pathJoin("hpc", hpc_ver))
load(pathJoin("hpc-intel", hpc_intel_ver))
load(pathJoin("hpc-impi", hpc_impi_ver))
load(pathJoin("grads", grads_ver))
load(pathJoin("prod_util", prod_util_ver))

load("common-run")


whatis("Description: GSI Monitoring run-time environment on S4")
