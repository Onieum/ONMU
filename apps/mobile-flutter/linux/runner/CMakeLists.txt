cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# application target을 정의합니다. 이름을 바꾸려면 여기 값이 아니라 top-level CMakeLists.txt의 BINARY_NAME을 변경합니다.
# 여기 값을 바꾸면 `flutter run`이 더 이상 동작하지 않습니다.
#
# application에 새 source file을 추가하면 여기에 등록해야 합니다.
add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# 표준 build setting 묶음을 적용합니다. 다른 build setting이 필요한 application에서는 제거할 수 있습니다.
apply_standard_settings(${BINARY_NAME})

# application ID용 preprocessor definition을 추가합니다.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# dependency library를 추가합니다. application 전용 dependency는 여기에 추가합니다.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
