help([[
]])

prepend_path("MODULEPATH", "/apps/test/hpc-stack/i-19.1.3.304__m-8.1.12__h-1.14.0__n-4.9.2__p-2.5.10__e-8.4.2/modulefiles/core")

local hpc_intel_ver=os.getenv("hpc_intel_ver") or "19.1.3.304"

--local intel_ver=os.getenv("intel_ver") or "19.1.3.304"
local prod_util_ver=os.getenv("prod_util_ver") or "2.0.13"
local prod_envir_ver=os.getenv("prod_envir_ver") or "2.0.6"

local netcdf_ver=os.getenv("netcdf_ver") or "4.7.4"
local wgrib2_ver=os.getenv("wgrib2_ver") or "2.0.8"

load(pathJoin("hpc-intel", hpc_intel_ver))
load(pathJoin("prod_util", prod_util_ver))
load(pathJoin("prod_envir", prod_envir_ver))

load(pathJoin("netcdf", netcdf_ver))
load(pathJoin("wgrib2", wgrib2_ver))

prepend_path("MODULEPATH", "/apps/test/lmodules/core/")
load ("GrADS/2.2.2")

whatis("Description: GSI Monitoring run-time environment on wcoss2")
