help([[
]])

local intel_ver=os.getenv("intel_ver") or "19.1.3.304"

load(pathJoin("intel", intel_ver))


prepend_path("MODULEPATH", "/apps/test/lmodules/core/")
load ("GrADS/2.2.2")

prepend_path("MODULEPATH", "/apps/ops/para/nco/modulefiles/core/")
load ("prod_util/2.0.13")

load("common-run")


whatis("Description: GSI Monitoring run-time environment on wcoss2")
