#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include "izn.h"

static wchar_t* utf8ToUtf16(const char* str)
{
  if (str == NULL) {
    return NULL;
  }

  int neededLen = MultiByteToWideChar(
                    CP_UTF8,
                    0,
                    str,
                    -1,
                    NULL,
                    0
                  );

  wchar_t* utf16Str = (wchar_t*)malloc(neededLen * sizeof(wchar_t));

  if (utf16Str == NULL) {
    return NULL;
  }

  MultiByteToWideChar(
    CP_UTF8,
    0,
    str,
    -1,
    utf16Str,
    neededLen
  );

  return utf16Str;
}

iznExport int iznExecCmd(const char* cmd)
{
  STARTUPINFOW si;
  PROCESS_INFORMATION pi;

  int exitCode = -1;

  if (cmd == NULL) {
    return exitCode;
  }

  ZeroMemory(&si, sizeof(si));
  ZeroMemory(&pi, sizeof(pi));

  si.cb = sizeof(si);
  si.dwFlags = STARTF_USESHOWWINDOW;
  si.wShowWindow = SW_HIDE;
  int cmdLen = strlen(cmd);
  char *prefix = "cmd.exe /c ";
  int prefixLen = strlen(prefix);
  char *prefixedCmd = malloc(prefixLen + cmdLen + 1);

  if (prefixedCmd == NULL) {
    return exitCode;
  }

  prefixedCmd[0] = '\0';

  strcat(prefixedCmd, prefix);
  strcat(prefixedCmd, cmd);

  wchar_t* utf16Cmd = utf8ToUtf16(prefixedCmd);

  free(prefixedCmd);

  if (utf16Cmd == NULL) {
    return exitCode;
  }

  BOOL isSuccess = CreateProcessW(
                     NULL,
                     utf16Cmd,
                     NULL,
                     NULL,
                     FALSE,
                     0,
                     NULL,
                     NULL,
                     &si,
                     &pi
                   );

  free(utf16Cmd);

  if (isSuccess) {
    WaitForSingleObject(pi.hProcess, INFINITE);
    GetExitCodeProcess(pi.hProcess, &exitCode);
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);
  }

  return exitCode;
}

iznExport iznWin iznGetActiveWin(void)
{
  HWND win = GetActiveWindow();

  return win;
}
