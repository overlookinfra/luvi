#include "GLFW/glfw3.h"
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static int lglfwInit(lua_State *L) {
  if (!glfwInit()) {
    return luaL_error(L, "Error initializing glfw");
  }
  return 0;
}

static int lglfwTerminate(lua_State *L) {
  glfwTerminate();
  return 0;
}

static void lglfw_on_close(GLFWwindow *window) {
  printf("Window %p closed!\n", window);
}

static int lglfwCreateWindow(lua_State *L) {
  GLFWwindow* window = glfwCreateWindow(640, 480, "My Title", NULL, NULL);
  glfwSetWindowCloseCallback(window, lglfw_on_close);
  lua_pushlightuserdata(L, window);
  return 1;
}

static int lglfwPollEvents(lua_State *L) {
  glfwPollEvents();
  return 0;
}

static const luaL_Reg lglfw_f[] = {
  {"init", lglfwInit},
  {"terminate", lglfwTerminate},
  {"createWindow", lglfwCreateWindow},
  {"pollEvents", lglfwPollEvents},
  {NULL, NULL}
};


LUALIB_API int luaopen_glfw(lua_State *L) {
  luaL_newlib(L, lglfw_f);
  return 1;
}
