help([[
Load common modules to run GSI Monitoring on all machines
]])

local wgrib2_ver=os.getenv("wgrib2_ver") or "2.0.8"

load(pathJoin("wgrib2", wgrib2_ver))

