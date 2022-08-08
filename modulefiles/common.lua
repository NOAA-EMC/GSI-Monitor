help([[
Load common modules to build GSI Monitoring on all machines
]])

local netcdf_ver=os.getenv("netcdf_ver") or "4.7.4"
local bacio=os.getenv("bacio_ver") or "2.4.1"
local w3emc_ver=os.getenv("w3emc_ver") or "2.9.2"
local ncdiag_ver=os.getenv("ncdiag_ver") or "1.0.0"

load(pathJoin("netcdf", netcdf_ver))
load(pathJoin("bacio", bacio_ver))
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("ncdiag", ncdiag_ver))
