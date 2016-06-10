set(LUA_CJSON_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/lua-cjson)

include_directories(
  ${LUA_CJSON_DIR}
)

add_library(lua_cjson
  ${LUA_CJSON_DIR}/lua_cjson.c
  ${LUA_CJSON_DIR}/strbuf.c
  ${LUA_CJSON_DIR}/fpconv.c
)

set(EXTRA_LIBS ${EXTRA_LIBS} lua_cjson)

# Handle platforms missing isinf() macro (Eg, some Solaris systems).
include(CheckSymbolExists)
CHECK_SYMBOL_EXISTS(isinf math.h HAVE_ISINF)
if(NOT HAVE_ISINF)
    add_definitions(-DUSE_INTERNAL_ISINF)
endif()

add_definitions(-DWITH_CJSON)
