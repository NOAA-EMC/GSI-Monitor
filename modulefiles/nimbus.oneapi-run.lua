help([[
]])

prepend_path("MODULEPATH", "/lfs/work/alexander_richert/stack/spack-stack/envs/g2-3.4.5-oneapi-2026.1.0-addon/modules_flat/Core")

local grads_ver=os.getenv("grads_ver") or "2.2.3"

load(pathJoin("grads", grads_ver))

load("common-run")

-- Restore oneAPI compiler libraries to front of LD_LIBRARY_PATH for precedence
-- Add libcilkrts from oneAPI 2023.2.1 for backwards compatibility
local oneapi_path = os.getenv("ONEAPI_LD_PATH") or ""
if oneapi_path ~= "" then
  prepend_path("LD_LIBRARY_PATH", "/opt/intel/oneapi/compiler/2023.2.1/linux/compiler/lib/intel64_lin")
  for dir in string.gmatch(oneapi_path, "[^:]+") do
    prepend_path("LD_LIBRARY_PATH", dir)
  end
end

whatis("Description: GSI Monitoring run-time environment on Nimbus with Intel oneAPI Compilers")
