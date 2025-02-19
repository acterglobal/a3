#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include "app_links/app_links_plugin_c_api.h"
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
#ifdef _DEBUG
  HWND hwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Acter-dev");
#else
  HWND hwnd = ::FindWindow(L"FLUTTER_RUNNER_WIN32_WINDOW", L"Acter");
#endif
  if (hwnd != NULL) {
    // Dispatch new link to current window
    SendAppLink(hwnd);
    ::ShowWindow(hwnd, SW_NORMAL);
    ::SetForegroundWindow(hwnd);
    return EXIT_FAILURE;
  }
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
#ifdef _DEBUG
  if (!window.CreateAndShow(L"Acter-dev", origin, size)) {
    return EXIT_FAILURE;
  }
#else
  if (!window.CreateAndShow(L"Acter", origin, size)) {
    return EXIT_FAILURE;
  }
#endif
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
