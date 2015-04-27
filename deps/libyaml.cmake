if (WithSharedYaml)
  find_package(Yaml REQUIRED)

  message("Yaml include dir: ${YAML_INCLUDE_DIR}")
  message("Yaml libraries: ${YAML_LIBRARIES}")

  include_directories(${YAML_INCLUDE_DIR})
  link_directories(${YAML_ROOT_DIR}/lib)
else (WithSharedYaml)
  message("Enabling Static YAML")
  add_subdirectory(deps/libyaml)
  include_directories(deps/libyaml/include)
endif (WithSharedYaml)

add_definitions(-DWITH_YAML)
include(deps/lyaml.cmake)
