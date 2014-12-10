set(LUA_SERVICE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/luaservice/LuaService/src)
set(LUA_SERVICE_UTIL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/deps/luaservice/LSvcUtil/src)


add_library(luaservice
  ${LUA_SERVICE_DIR}/LuaMain.c
  ${LUA_SERVICE_DIR}/LuaService.c
  ${LUA_SERVICE_DIR}/SvcController.c
  ${LUA_SERVICE_DIR}/SvcController.c
  ${LUA_SERVICE_UTIL_DIR}/SvcUtil.c
  ${LUA_SERVICE_UTIL_DIR}/LSvcUtil.rc
)

set(EXTRA_LIBS ${EXTRA_LIBS} luaservice)
