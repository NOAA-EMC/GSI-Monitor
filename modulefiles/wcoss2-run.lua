help([[
]])

local intel_ver=os.getenv("intel_ver") or "19.1.3.304"

load(pathJoin("intel", intel_ver))


prepend_path("MODULEPATH", "/apps/test/lmodules/core/")
load ("GrADS/2.2.2")


load("common-run")


whatis("Description: GSI Monitoring run-time environment on wcoss2")
