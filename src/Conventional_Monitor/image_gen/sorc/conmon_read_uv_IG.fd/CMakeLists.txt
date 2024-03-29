if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fp-model strict -assume byterecl -convert big_endian")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fconvert=big-endian -ffree-line-length-0 -ffast-math -fno-second-underscore -frecord-marker=4")
endif()

list(APPEND SRCS
  convinfo.f90
  histgram.f90
  histgramuv.f90
  mainread_uv.f90
  read_uv.f90
  read_uv_mor.f90
  rm_dups.f90
)

add_executable(conmon_read_uv_IG.x ${SRCS})

target_compile_definitions(conmon_read_uv_IG.x PRIVATE "_REAL8_")
target_link_libraries(conmon_read_uv_IG.x PRIVATE NetCDF::NetCDF_Fortran)
target_link_libraries(conmon_read_uv_IG.x PRIVATE ncdiag::ncdiag_serial)
target_link_libraries(conmon_read_uv_IG.x PRIVATE w3emc::w3emc_4)

# Install executable targets
install(TARGETS conmon_read_uv_IG.x RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

