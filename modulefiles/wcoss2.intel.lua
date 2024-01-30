help([[
]])

local PrgEnv_intel_ver=os.getenv("PrgEnv_intel_ver") or "8.1.0"
local intel_ver=os.getenv("intel_ver") or "19.1.3.304"
local craype_ver=os.getenv("craype_ver") or "2.7.8"
local cray_mpich_ver=os.getenv("cray_mpich_ver") or "8.1.7"
local cmake_ver= os.getenv("cmake_ver") or "3.20.2"

local netcdf_ver=os.getenv("netcdf_ver") or "4.7.4"
local bacio_ver=os.getenv("bacio_ver") or "2.4.1"
local w3emc_ver=os.getenv("w3emc_ver") or "2.9.2"
local ncdiag_ver=os.getenv("ncdiag_ver") or "1.0.0"

load(pathJoin("PrgEnv-intel", PrgEnv_intel_ver))
load(pathJoin("intel", intel_ver))
load(pathJoin("craype", craype_ver))
load(pathJoin("cray-mpich", cray_mpich_ver))
load(pathJoin("cmake", cmake_ver))

load(pathJoin("netcdf", netcdf_ver))
load(pathJoin("bacio", bacio_ver))
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("ncdiag", ncdiag_ver))

whatis("Description: GSI Monitoring environment on WCOSS2")
