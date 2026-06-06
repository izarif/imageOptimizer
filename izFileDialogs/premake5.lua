workspace("izfdWorkspace")
  configurations{"debug", "release"}
  platforms{"32bit", "64bit"}
  
  filter("platforms:32bit")
  architecture("x86")

  filter("platforms:64bit")
  architecture("x64")

  filter("configurations:release")
  optimize("Speed")

  filter("action:vs*")
  toolset("v141_xp")
  defines{
    "_WIN32_WINNT=0x0600",
    "_USING_V110_SDK71_",
    "_CRT_SECURE_NO_WARNINGS",
  }

  buildoptions{
    "/W3",
  }

project("izfd")
  kind("SharedLib")
  language("C")
    includedirs{
    "src/include",
  }

  files{
    "src/nfd_common.c",
    "src/nfd_lua.c",
  }

  filter("action:vs*")
  linkoptions{
    "/DEF:izfd.def",
  }

  filter("system:windows")
  includedirs{
    "buildDeps/lua",
    "buildDeps/izn",
  }

  files{
    "src/nfd_win.cpp",
  }

  links{
    "buildDeps/lua/lua51.lib",
    "buildDeps/izn/izn.lib",
  }
