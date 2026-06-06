#include <stdlib.h>
#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include "izn.h"

// code for unix platform is untested

iznExport int iznExecCmd(const char* cmd)
{
  int exitCode = system(cmd);

  return exitCode;
}

iznExport iznWin iznGetActiveWin(void)
{
  Atom type;
  int format;
  unsigned long itemsCount;
  unsigned long bytesLeft;
  unsigned char *prop;
  unsigned char *data;

  Display *disp = XOpenDisplay(NULL);
  Atom prop = XInternAtom(disp, "_NET_ACTIVE_WINDOW", False);
  Window root = DefaultRootWindow(disp);
  Window win = 0;

  int status = XGetWindowProperty(
                 disp,
                 root,
                 prop,
                 0,
                 1,
                 False,
                 XA_WINDOW,
                 &type,
                 &format,
                 &itemsCount,
                 &bytesLeft,
                 &data
               );

  if (status == Success) {
    win = ((Window)data)[0];
  }

  XFree(data);

  return win;
}
