if(NOT ${BUILD_UTIL_FOR_NCO})
   add_subdirectory(data_extract)
   add_subdirectory(image_gen)
endif()

add_subdirectory(nwprod)
