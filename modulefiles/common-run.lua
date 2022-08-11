help([[
Load common modules to run GSI Monitoring on all machines
]])

local wgrib2_ver=os.getenv("wgrib2_ver") or "2.0.8"
--local prod_util_ver=os.getenv("prod_util_ver") or "1.2.2"

load(pathJoin("wgrib2", wgrib2_ver))
--load(pathJoin("prod_util", prod_util_ver))

