#ifndef RUNNER_WIN32_WINDOW_H_
#define RUNNER_WIN32_WINDOW_H_

#include <windows.h>

#include <functional>
#include <memory>
#include <string>

// high DPI-aware Win32 Window용 class abstraction입니다.
// custom rendering과 input handling을 특화하려는 class가 상속하도록 의도되었습니다.
class Win32Window {
 public:
  struct Point {
    unsigned int x;
    unsigned int y;
    Point(unsigned int x, unsigned int y) : x(x), y(y) {}
  };

  struct Size {
    unsigned int width;
    unsigned int height;
    Size(unsigned int width, unsigned int height)
        : width(width), height(height) {}
  };

  Win32Window();
  virtual ~Win32Window();

  // |title|을 가진 Win32 window를 |origin|과 |size| 기준으로 생성합니다.
  // 새 window는 default monitor에 만들어집니다.
  // OS에는 physical pixel 기준으로 window size가 전달되므로, 일관된 size를 위해 default monitor에 맞게 width/height를 scale합니다.
  // |Show|가 호출될 때까지 window는 보이지 않습니다. 생성에 성공하면 true를 반환합니다.
  bool Create(const std::wstring& title, const Point& origin, const Size& size);

  // 현재 window를 표시합니다. 성공적으로 표시되면 true를 반환합니다.
  bool Show();

  // window와 연결된 OS resource를 해제합니다.
  void Destroy();

  // |content|를 window tree에 삽입합니다.
  void SetChildContent(HWND content);

  // client가 icon과 다른 window property를 설정할 수 있도록 backing Window handle을 반환합니다.
  // window가 destroy된 경우 nullptr를 반환합니다.
  HWND GetHandle();

  // true이면 이 window를 닫을 때 application이 종료됩니다.
  void SetQuitOnClose(bool quit_on_close);

  // 현재 client area의 bounds를 나타내는 RECT를 반환합니다.
  RECT GetClientArea();

 protected:
  // mouse handling, size change, DPI 관련 주요 window message를 처리하고 route합니다.
  // 상속 class가 처리할 수 있도록 member overload에 위임합니다.
  virtual LRESULT MessageHandler(HWND window,
                                 UINT const message,
                                 WPARAM const wparam,
                                 LPARAM const lparam) noexcept;

  // CreateAndShow 호출 시 실행되며 subclass가 window 관련 setup을 할 수 있게 합니다.
  // setup이 실패하면 subclass는 false를 반환해야 합니다.
  virtual bool OnCreate();

  // Destroy가 호출될 때 실행됩니다.
  virtual void OnDestroy();

 private:
  friend class WindowClassRegistrar;

  // message pump가 호출하는 OS callback입니다.
  // non-client area가 생성될 때 전달되는 WM_NCCREATE message를 처리하고 자동 non-client DPI scaling을 활성화합니다.
  // 이를 통해 non-client area가 DPI 변화에 자동으로 반응합니다.
  // 다른 message는 MessageHandler가 처리합니다.
  static LRESULT CALLBACK WndProc(HWND const window,
                                  UINT const message,
                                  WPARAM const wparam,
                                  LPARAM const lparam) noexcept;

  // |window|에 해당하는 class instance pointer를 가져옵니다.
  static Win32Window* GetThisFromHandle(HWND const window) noexcept;

  // system theme에 맞게 window frame theme를 갱신합니다.
  static void UpdateTheme(HWND const window);

  bool quit_on_close_ = false;

  // top-level window의 window handle입니다.
  HWND window_handle_ = nullptr;

  // hosted content의 window handle입니다.
  HWND child_content_ = nullptr;
};

#endif  // RUNNER_WIN32_WINDOW_H_
