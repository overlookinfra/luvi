set(YAML_SHARED yaml)
set(YAML_STATIC yamlstatic)

set(LUA_YAML_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/lyaml)

if (WithSharedYAML)
  set(LUA_YAML_LIB ${YAML_SHARED})
else ()
  set(LUA_YAML_LIB ${YAML_STATIC})
endif()

add_library(lyaml
  ${LUA_YAML_DIR}/ext/yaml/emitter.c
  ${LUA_YAML_DIR}/ext/yaml/parser.c
  ${LUA_YAML_DIR}/ext/yaml/scanner.c
  ${LUA_YAML_DIR}/ext/yaml/yaml.c
)

target_link_libraries(lyaml ${LUA_YAML_LIB})

set(EXTRA_LIBS ${EXTRA_LIBS} lyaml)

