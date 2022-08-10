help([[
Load common modules to run GSI Monitoring on all machines
]])

local wgrib2=os.getenv("wgrib2") or "2.0.8"
local prod_util=os.getenv("prod_util") or "1.2.2"

load(pathJoin("wgrib2", wgrib2_ver))
load(pathJoin("prod_util", prod_util_ver))

