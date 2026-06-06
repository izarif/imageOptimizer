#ifndef iznH
#define iznH

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_MSC_VER)
#if defined(iznDll)
#define iznExport __declspec(dllexport)
#else
#define iznExport __declspec(dllimport)
#endif
#elif defined(__GNUC__) || defined(__clang__)
#define iznExport __attribute__((visibility("default")))
#endif

#ifdef _WIN32
#include <windows.h>

typedef HWND iznWin;
#else
#include <X11/Xlib.h>

typedef Window iznWin;
#endif

iznExport const char* iznGetOsName(void);
iznExport int iznExecCmd(const char* cmd);
iznExport iznWin iznGetActiveWin(void);

#ifdef __cplusplus
}
#endif

#endif
