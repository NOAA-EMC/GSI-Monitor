help([[
]])

prepend_path("MODULEPATH", "/scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/modulefiles/stack")

local hpc_ver=os.getenv("hpc_ver") or "1.1.0"
local hpc_gnu_ver=os.getenv("hpc_gnu_ver") or "9.2.0"
local grads=os.getenv("grads") or "2.2.1"

load(pathJoin("hpc", hpc_ver))
load(pathJoin("hpc-gnu", hpc_gnu_ver))
load(pathJoin("grads", grads_ver))

load("common-run")

whatis("Description: GSI Monitoring environment on Hera with GNU Compilers")
