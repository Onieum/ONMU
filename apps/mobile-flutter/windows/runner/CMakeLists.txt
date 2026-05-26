cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# application target을 정의합니다. 이름을 바꾸려면 여기 값이 아니라 top-level CMakeLists.txt의 BINARY_NAME을 변경합니다.
# 여기 값을 바꾸면 `flutter run`이 더 이상 동작하지 않습니다.
#
# application에 새 source file을 추가하면 여기에 등록해야 합니다.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# 표준 build setting 묶음을 적용합니다. 다른 build setting이 필요한 application에서는 제거할 수 있습니다.
apply_standard_settings(${BINARY_NAME})

# build version용 preprocessor definition을 추가합니다.
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION=\"${FLUTTER_VERSION}\"")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}")
target_compile_definitions(${BINARY_NAME} PRIVATE "FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}")

# C++ standard library function과 충돌하는 Windows macro를 비활성화합니다.
target_compile_definitions(${BINARY_NAME} PRIVATE "NOMINMAX")

# dependency library와 include directory를 추가합니다. application 전용 dependency는 여기에 추가합니다.
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_link_libraries(${BINARY_NAME} PRIVATE "dwmapi.lib")
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# build 중 Flutter tool 부분을 실행합니다. 제거하면 안 됩니다.
add_dependencies(${BINARY_NAME} flutter_assemble)
