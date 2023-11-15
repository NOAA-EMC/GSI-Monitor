help([[
]])

prepend_path("MODULEPATH", "/scratch1/NCEPDEV/nems/role.epic/spack-stack/spack-stack-1.5.1/envs/gsi-addon/install/modulefiles/Core")

local stack_gnu_ver=os.getenv("stack_gnu_ver") or "9.2.0"
local stack_openmpi_ver=os.getenv("stack_openmpi_ver") or "4.1.5"
local cmake_ver=os.getenv("cmake_ver") or "3.23.1"

load(pathJoin("stack-gcc", stack_gnu_ver))
load(pathJoin("stack-openmpi", stack_openmpi_ver))
load(pathJoin("cmake", cmake_ver))

load("common")

whatis("Description: GSI Monitoring environment on Hera with GNU Compilers")
