help([[
]])

prepend_path("MODULEPATH", "/lfs/work/alexander_richert/stack/spack-stack/envs/g2-3.4.5-oneapi-2026.1.0-addon/modules_flat/Core")

local netcdf_c_ver=os.getenv("netcdf_c_ver") or "4.9.2"
local netcdf_fortran_ver=os.getenv("netcdf_fortran_ver") or "4.6.1"
local bacio_ver=os.getenv("bacio_ver") or "2.4.1"
local w3emc_ver=os.getenv("w3emc_ver") or "2.13.0"
local ncdiag_ver=os.getenv("ncdiag_ver") or "1.1.3"
local cmake_ver=os.getenv("cmake_ver") or "3.31.11"

load(pathJoin("cmake", cmake_ver))
load(pathJoin("netcdf-c", netcdf_c_ver))
load(pathJoin("netcdf-fortran", netcdf_fortran_ver))

load(pathJoin("bacio", bacio_ver))
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("gsi-ncdiag", ncdiag_ver))

-- Set Intel oneAPI compilers for CMake
setenv("FC", "/opt/intel/oneapi/compiler/2026.1/bin/ifx")
setenv("CC", "/opt/intel/oneapi/compiler/2026.1/bin/icx")
setenv("CXX", "/opt/intel/oneapi/compiler/2026.1/bin/icpx")

-- Restore oneAPI compiler libraries to front of LD_LIBRARY_PATH for precedence
-- Add libcilkrts from oneAPI 2023.2.1 for backwards compatibility
local oneapi_path = os.getenv("ONEAPI_LD_PATH") or ""
if oneapi_path ~= "" then
  prepend_path("LD_LIBRARY_PATH", "/opt/intel/oneapi/compiler/2023.2.1/linux/compiler/lib/intel64_lin")
  for dir in string.gmatch(oneapi_path, "[^:]+") do
    prepend_path("LD_LIBRARY_PATH", dir)
  end
end

whatis("Description: GSI Monitoring environment on Nimbus with Intel oneAPI Compilers")
