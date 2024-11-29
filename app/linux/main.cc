#include "my_application.h"

int main(int argc, char** argv) {
#ifndef NDEBUG
  printf("This app works in debug mode\n");
#else
  printf("This app works in release mode\n");
#endif

  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
