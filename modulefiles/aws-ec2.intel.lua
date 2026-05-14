help([[
]])

prepend_path("MODULEPATH", "/opt/spack-stack/envs/ue-oneapi-2024.2.1/install/modulefiles/Core")
prepend_path("MODULEPATH", "/opt/modulefiles")

local stack_oneapi_ver=os.getenv("stack_oneapi_ver") or "2024.2.1"
local stack_impi_ver=os.getenv("stack_impi_ver") or "2021.13"
local cmake_ver=os.getenv("cmake_ver") or "3.27.9"

load(pathJoin("stack-oneapi", stack_oneapi_ver))
load(pathJoin("stack-intel-oneapi-mpi", stack_impi_ver))
load(pathJoin("cmake", cmake_ver))

load("common")

whatis("Description: GSI Monitoring environment on AWS ec2 with Intel Compilers")
