workspace("iznWorkspace")
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
    "_WIN32_WINNT=0x0501",
    "_USING_V110_SDK71_",
    "_CRT_SECURE_NO_WARNINGS",
  }

  buildoptions{
    "/W3",
  }

project("izn")
  kind("SharedLib")
  language("C")
  files{
    "src/iznCommon.c",
  }

  filter("system:windows")
  includedirs{
    "buildDeps/lua",
  }

  defines{
    "iznDll",
  }

  files{
    "src/iznWin.c",
  }

  links{
    "buildDeps/lua/lua51.lib",
  }
