# project 수준 설정입니다.
cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# application용 executable 이름입니다. 디스크에 표시되는 application 이름을 바꾸려면 이 값을 변경합니다.
set(BINARY_NAME "onmu_mobile")
# 이 application의 고유 GTK application identifier입니다. 참고:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "io.onieum.onmu_mobile")

# 최신 CMake에서 warning이 나지 않도록 modern CMake 동작을 명시적으로 사용합니다.
cmake_policy(SET CMP0063 NEW)

# binary 기준 상대 경로의 lib/ directory에서 bundled library를 load합니다.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# cross-build용 root filesystem입니다.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# build configuration option을 정의합니다.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# 대부분의 target에 적용할 compilation 설정입니다.
#
# plugin이 기본적으로 이 function을 사용하므로 새 option 추가에 주의합니다.
# 대부분의 경우 이 function을 수정하기보다 특정 target에만 새 option을 추가합니다.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library와 tool build rule입니다.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# system-level dependency입니다.
find_package(PkgConfig REQUIRED)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0)

# application build입니다. runner/CMakeLists.txt를 참고합니다.
add_subdirectory("runner")

# build 중 Flutter tool 부분을 실행합니다. 제거하면 안 됩니다.
add_dependencies(${BINARY_NAME} flutter_assemble)

# install로 생성된 bundle 안의 executable copy만 정상 실행됩니다.
# resource가 올바른 상대 위치에 있어야 하기 때문입니다.
# bundle 밖의 copy를 실행하는 일을 막기 위해 기본 top-level 위치 대신 subdirectory에 둡니다.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# 생성된 plugin build rule입니다. plugin build와 application 추가를 관리합니다.
include(flutter/generated_plugins.cmake)


# === 설치 ===
# 기본적으로 "install"은 build directory에 relocatable bundle을 만듭니다.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# 매번 깨끗한 build bundle directory에서 시작합니다.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# 모든 package의 build.dart가 제공한 native asset을 복사합니다.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# 이전 install에서 남은 stale file을 피하기 위해 build마다 assets directory를 완전히 다시 복사합니다.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# non-Debug build에서만 AOT library를 설치합니다.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
