help([[
]])

local intel_ver=os.getenv("intel_ver") or "19.1.3.304"
local craype_ver=os.getenv("craype_ver") or "2.7.13"
local cray_mpich_ver=os.getenv("cray_mpich_ver") or "8.1.9"
local prod_util_ver=os.getenv("prod_util_ver") or "2.0.13"
local prod_envir_ver=os.getenv("prod_envir_ver") or "2.0.6"

local hdf5_ver=os.getenv("hdf5_ver") or "1.14.0"
local pnetcdf_ver=os.getenv("pnetcdf_ver") or "1.12.2"
local netcdf_ver=os.getenv("netcdf_ver") or "4.9.2"
local wgrib2_ver=os.getenv("wgrib2_ver") or "2.0.8"

load(pathJoin("intel", intel_ver))
load(pathJoin("craype", craype_ver))
load(pathJoin("cray-mpich", cray_mpich_ver))
load(pathJoin("prod_util", prod_util_ver))
load(pathJoin("prod_envir", prod_envir_ver))

load(pathJoin("hdf5-D", hdf5_ver))
load(pathJoin("pnetcdf-D", pnetcdf_ver))
load(pathJoin("netcdf-D", netcdf_ver))
load(pathJoin("wgrib2", wgrib2_ver))

prepend_path("MODULEPATH", "/apps/test/lmodules/core/")
load ("GrADS/2.2.2")

whatis("Description: GSI Monitoring run-time environment on wcoss2")
