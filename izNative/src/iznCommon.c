#include "lua.h"
#include "lauxlib.h"
#include "izn.h"

iznExport const char* iznGetOsName(void)
{
  const char* osName = "unix";

#ifdef _WIN32
  osName = "windows";
#elif defined(__linux__)
  osName = "linux";
#elif defined(__APPLE__)
#include "TargetConditionals.h"

#ifdef TARGET_OS_OSX
  osName = "macos";
#endif
#elif defined(__FreeBSD__)
  osName = "freebsd";
#elif defined((__ANDROID_API__)
  osName = "android";
#endif

  return osName;
}

static int lGetOsName(lua_State* L)
{
  const char* osName  = iznGetOsName();

  lua_pushstring(L, osName);

  return 1;
}

static int lExecCmd(lua_State* L)
{
  const char* cmd  = luaL_checkstring(L, 1);
  int exitCode = iznExecCmd(cmd);

  lua_pushnumber(L, exitCode);

  return 1;
}

static const struct luaL_Reg lFuncs[] = {
  {"getOsName", lGetOsName},
  {"execCmd", lExecCmd},
  {NULL, NULL}
};

iznExport int luaopen_izn(lua_State* L)
{
  luaL_newlib(L, lFuncs);

  return 1;
}
