help([[
Load common modules to run GSI Monitoring on all machines
]])

local netcdf_c_ver=os.getenv("netcdf_c_ver") or "4.9.2"
local netcdf_fortran_ver=os.getenv("netcdf_fortran_ver") or "4.6.1"
local wgrib2_ver=os.getenv("wgrib2_ver") or "2.0.8"

load(pathJoin("netcdf-c", netcdf_c_ver))
load(pathJoin("netcdf-fortran", netcdf_fortran_ver))
load(pathJoin("wgrib2", wgrib2_ver))

