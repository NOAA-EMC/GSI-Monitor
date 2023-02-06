help([[
Load common modules to run GSI Monitoring on all machines
]])

local netcdf_ver=os.getenv("netcdf_ver") or "4.7.4"
local wgrib2_ver=os.getenv("wgrib2_ver") or "2.0.8"

load(pathJoin("netcdf", netcdf_ver))
load(pathJoin("wgrib2", wgrib2_ver))

