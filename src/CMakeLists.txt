if(BUILD_UTIL_MINMON)
  add_subdirectory(Minimization_Monitor)
endif()

if(BUILD_UTIL_CONMON)
  add_subdirectory(Conventional_Monitor)
endif()

if(BUILD_UTIL_OZNMON)
  add_subdirectory(Ozone_Monitor)
endif()

if(BUILD_UTIL_RADMON)
  add_subdirectory(Radiance_Monitor)
endif()
