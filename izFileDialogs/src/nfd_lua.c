#include "lua.h"
#include "lauxlib.h"
#include "nfd.h"

static int l_open(lua_State* L)
{
  nfdchar_t* outPath;
  const nfdchar_t* filter = luaL_optstring(L, 1, NULL);
  const nfdchar_t* defaultPath = luaL_optstring(L, 2, NULL);
  nfdresult_t result = NFD_OpenDialog(filter, defaultPath, &outPath);

  switch (result) {
  case NFD_OKAY:
    lua_pushstring(L, outPath);

    return 1;
  case NFD_CANCEL:
    lua_pushboolean(L, 9);

    return 1;
  case NFD_ERROR:
    lua_pushstring(L, NFD_GetError());
    lua_error(L); // always returns here

    return -1;
  default:
    return 0;
  }
}

static int l_openFolder(lua_State* L)
{
  nfdchar_t* outPath;
  const nfdchar_t* defaultPath = luaL_optstring(L, 1, NULL);
  nfdresult_t result = NFD_PickFolder(defaultPath, &outPath);

  switch (result) {
  case NFD_OKAY:
    lua_pushstring(L, outPath);

    return 1;
  case NFD_CANCEL:
    lua_pushboolean(L, 0);

    return 1;
  case NFD_ERROR:
    lua_pushstring(L, NFD_GetError());
    lua_error(L); // always returns here

    return -1;
  default:
    return 0;
  }
}

static void push_pathset(lua_State* L, nfdpathset_t* set)
{
  size_t count = NFD_PathSet_GetCount(set);

  lua_createtable(L, count, 0);

  int tbl = lua_gettop(L);

  for (size_t i = 0; i < count; i++) {
    lua_pushstring(L, NFD_PathSet_GetPath(set, i));
    lua_rawseti(L, tbl, i + 1);
  }

  NFD_PathSet_Free(set);
}

static int l_openMany(lua_State* L)
{
  nfdpathset_t outPaths;
  const nfdchar_t* filter = luaL_optstring(L, 1, NULL);
  const nfdchar_t* defaultPath = luaL_optstring(L, 2, NULL);
  nfdresult_t result = NFD_OpenDialogMultiple(filter, defaultPath, &outPaths);

  switch (result) {
  case NFD_OKAY:
    push_pathset(L, &outPaths);

    return 1;
  case NFD_CANCEL:
    lua_pushboolean(L, 0);

    return 1;
  case NFD_ERROR:
    lua_pushstring(L, NFD_GetError());
    lua_error(L); // always returns here

    return -1;
  default:
    return 0;
  }
}

static int l_save(lua_State* L)
{
  nfdchar_t* outPath;
  const nfdchar_t* filter = luaL_optstring(L, 1, NULL);
  const nfdchar_t* defaultPath = luaL_optstring(L, 2, NULL);
  nfdresult_t result = NFD_SaveDialog(filter, defaultPath, &outPath);

  switch (result) {
  case NFD_OKAY:
    lua_pushstring(L, outPath);

    return 1;
  case NFD_CANCEL:
    lua_pushboolean(L, 0);

    return 1;
  case NFD_ERROR:
    lua_pushstring(L, NFD_GetError());
    lua_error(L); // always returns here

    return -1;
  default:
    return 0;
  }
}

static int l_openMany2(lua_State* L)
{
  nfdpathset_t outPaths;
  const nfdchar_t* filter = luaL_optstring(L, 1, NULL);
  const nfdchar_t* defaultPath = luaL_optstring(L, 2, NULL);
  nfdresult_t result = NFD_OpenDialogMultiple2(filter, defaultPath, &outPaths);

  switch (result) {
  case NFD_OKAY:
    push_pathset(L, &outPaths);

    return 1;
  case NFD_CANCEL:
    lua_pushboolean(L, 0);

    return 1;
  case NFD_ERROR:
    lua_pushstring(L, NFD_GetError());
    lua_error(L); // always returns here

    return -1;
  default:
    return 0;
  }
}

static const struct luaL_Reg l_funcs[] = {
  {"open", l_open},
  {"openFolder", l_openFolder},
  {"openMany", l_openMany},
  {"save", l_save},
  {"openMany2", l_openMany2},
  {NULL, NULL}
};

int luaopen_izfd(lua_State* L)
{
  luaL_newlib(L, l_funcs);

  return 1;
}
