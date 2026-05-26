#ifndef RUNNER_UTILS_H_
#define RUNNER_UTILS_H_

#include <string>
#include <vector>

// process용 console을 만들고 runner와 Flutter library의 stdout/stderr를 그 console로 redirect합니다.
void CreateAndAttachConsole();

// null-terminated UTF-16 wchar_t*를 받아 UTF-8 std::string으로 반환합니다. 실패하면 빈 string을 반환합니다.
std::string Utf8FromUtf16(const wchar_t* utf16_string);

// 전달된 command line argument를 UTF-8 std::vector<std::string>으로 가져옵니다. 실패하면 빈 vector를 반환합니다.
std::vector<std::string> GetCommandLineArguments();

#endif  // RUNNER_UTILS_H_
