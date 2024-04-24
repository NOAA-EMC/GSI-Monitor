help([[
]])

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.6.0/envs/gsi-addon-dev-rocky8/install/modulefiles/Core")

local stack_gnu_ver=os.getenv("stack_gnu_ver") or "9.2.0"
local stack_openmpi_ver=os.getenv("stack_openmpi_ver") or "4.1.5"
local prod_util_ver=os.getenv("prod_util_ver") or "2.1.1"
local grads_ver=os.getenv("grads_ver") or "2.2.3"
local perl_ver=os.getenv("perl_ver") or "5.38.0"

load(pathJoin("stack-gcc", stack_gnu_ver))
load(pathJoin("stack-openmpi", stack_openmpi_ver))
load(pathJoin("grads", grads_ver))
load(pathJoin("prod_util", prod_util_ver))

load("common-run")

whatis("Description: GSI Monitoring environment on Hera with GNU Compilers")
