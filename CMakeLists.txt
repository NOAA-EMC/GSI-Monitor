cmake_minimum_required(VERSION 3.20)

project(gsimon
        VERSION 1.0.0
        LANGUAGES Fortran)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
set(CMAKE_DIRECTORY_LABELS ${PROJECT_NAME})

include(GNUInstallDirs)

if(NOT CMAKE_BUILD_TYPE MATCHES "^(Debug|Release|RelWithDebInfo|MinSizeRel)$")
  message(STATUS "Setting build type to 'Release' as none was specified.")
  set(CMAKE_BUILD_TYPE
      "Release"
      CACHE STRING "Choose the type of build." FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release" "MinSizeRel" "RelWithDebInfo")
endif()

if(NOT CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU|Intel)$")
  message(WARNING "${CMAKE_Fortran_COMPILER_ID} is not supported.")
endif()

# Build options
option(BUILD_UTIL_ALLMON "Build all monitoring utilities" OFF)
option(BUILD_UTIL_MINMON "Build Minimization Monitoring Utilities" OFF)
option(BUILD_UTIL_CONMON "Build Conventional Monitoring Utilities" OFF)
option(BUILD_UTIL_OZNMON "Build Ozone Monitoring Utilities" OFF)
option(BUILD_UTIL_RADMON "Build Radiance Monitoring Utilities" OFF)

option(BUILD_UTIL_FOR_NCO "Build only Operational Portions of the Monitor Utilities" OFF)

# If building all monitors, then force all options to ON
if (BUILD_UTIL_ALLMON)
  set(BUILD_UTIL_MINMON ON CACHE BOOL "Build Minimization Monitoring Utilities" FORCE)
  set(BUILD_UTIL_CONMON ON CACHE BOOL "Build Conventional Monitoring Utilities" FORCE)
  set(BUILD_UTIL_OZNMON ON CACHE BOOL "Build Ozone Monitoring Utilities" FORCE)
  set(BUILD_UTIL_RADMON ON CACHE BOOL "Build Radiance Monitoring Utilities" FORCE)
endif()

# Echo user options
message(STATUS "BUILD_UTIL_MINMON ... ${BUILD_UTIL_MINMON}")
message(STATUS "BUILD_UTIL_CONMON ... ${BUILD_UTIL_CONMON}")
message(STATUS "BUILD_UTIL_OZNMON ... ${BUILD_UTIL_OZNMON}")
message(STATUS "BUILD_UTIL_RADMON ... ${BUILD_UTIL_RADMON}")

# Dependencies
find_package(NetCDF REQUIRED Fortran)
find_package(ncdiag REQUIRED)
find_package(w3emc REQUIRED)

# Get compiler flags for the utilities
include(gsimon_compiler_flags)

add_subdirectory(src)
