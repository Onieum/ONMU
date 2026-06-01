import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/character/character_start_page.dart';
import 'features/launch/splash_page.dart';
import 'features/home/home_page.dart';
import 'features/ootd/ootd_list_page.dart';
import 'features/ootd/presentation/pages/daily_record_screen.dart';
import 'features/ootd/presentation/pages/ootd_record_screen.dart';
import 'features/memory/presentation/pages/memory_detail_page.dart';
import 'features/memory/presentation/pages/memory_diary_template_page.dart';
import 'main_shell.dart';
import 'shared/models/ootd_model.dart';
import 'shared/providers/state_providers.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OnmuApp(),
    ),
  );
}

class OnmuApp extends ConsumerStatefulWidget {
  const OnmuApp({super.key});

  @override
  ConsumerState<OnmuApp> createState() => _OnmuAppState();
}

class _OnmuAppState extends ConsumerState<OnmuApp> {
  late final GoRouter _router;
  late final _RouterRefreshNotifier _refreshNotifier;

  @override
  void initState() {
    super.initState();
    
    _refreshNotifier = _RouterRefreshNotifier();
    
    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: _refreshNotifier,
      redirect: (context, state) {
        final showSplash = ref.read(showSplashProvider);
        final character = ref.read(userCharacterProvider);
        final location = state.matchedLocation;

        if (showSplash) {
          return '/splash';
        }

        if (character == null) {
          if (location.startsWith('/character')) {
            return null;
          }
          return '/character/start';
        }

        if (location == '/splash' || location == '/character/start') {
          return '/home';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => SplashPage(
            onTimeout: () {
              ref.read(showSplashProvider.notifier).state = false;
            },
          ),
        ),
        GoRoute(
          path: '/character/start',
          builder: (context, state) => CharacterStartPage(
            onCompleted: (character) {
              ref.read(userCharacterProvider.notifier).state = character;
            },
          ),
        ),
        
        // StatefulShellRoute로 하단 탭 내비게이션 바 구성
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            // 탭 0: 홈
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomePage(),
                ),
              ],
            ),
            // 탭 1: 온모임
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/onchat',
                  builder: (context, state) => const _TabPlaceholder(
                    title: '온모임 탭',
                    todoText: '온모임 목록 화면 개발 예정',
                  ),
                ),
              ],
            ),
            // 탭 3: 기록 (OotdListPage)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/ootd/list',
                  builder: (context, state) {
                    final character = ref.watch(userCharacterProvider)!;
                    final records = ref.watch(customRecordsProvider);
                    return OotdListPage(
                      userCharacter: character,
                      customRecords: records,
                      onAddOotd: (date, ootdRecord) {
                        context.push(
                          '/ootd/new/ootd?date=${date.toIso8601String()}',
                          extra: ootdRecord,
                        );
                      },
                      onAddDailyRecord: (date, ootdRecord) {
                        // ootdRecord가 있으면 query parameter 대신 extra로 전달할 수 있도록 함
                        context.push(
                          '/ootd/new/daily?date=${date.toIso8601String()}',
                          extra: ootdRecord,
                        );
                      },
                      onViewOotdDetail: (record) {
                        // 기록 상세(기억 상세) 페이지 이동
                        final type = record.brands['recordType'] ?? 'ootd';
                        final recordKey = '${record.date.year}-${record.date.month}-${record.date.day}-$type';
                        context.push('/memories/$recordKey');
                      },
                      onNavigateToProfile: () {
                        // 캐릭터 초기화 다이얼로그 호출
                        _showResetDialog(context);
                      },
                    );
                  },
                ),
              ],
            ),
            // 탭 4: 마이
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/my',
                  builder: (context, state) => const _TabPlaceholder(
                    title: '마이 탭',
                    todoText: '마이페이지 개발 예정',
                  ),
                ),
              ],
            ),
          ],
        ),

        // 기록 등록 화면들 (풀스크린 모달 형태)
        GoRoute(
          path: '/ootd/new/daily',
          builder: (context, state) {
            final dateStr = state.uri.queryParameters['date'] ?? DateTime.now().toIso8601String();
            final date = DateTime.parse(dateStr);
            final ootdRecord = state.extra as OotdRecord?;
            final character = ref.read(userCharacterProvider)!;

            return DailyRecordScreen(
              userCharacter: character,
              recordDate: date,
              ootdRecord: ootdRecord,
              onSave: (newRecord) {
                ref.read(customRecordsProvider.notifier).update((state) {
                  final type = newRecord.brands['recordType'] ?? 'daily';
                  final index = state.indexWhere((r) =>
                      r.date.year == newRecord.date.year &&
                      r.date.month == newRecord.date.month &&
                      r.date.day == newRecord.date.day &&
                      (r.brands['recordType'] ?? 'daily') == type);
                  if (index != -1) {
                    final list = List<OotdRecord>.from(state);
                    list[index] = newRecord;
                    return list;
                  }
                  return [...state, newRecord];
                });
              },
              onCreateOotd: () {
                context.push('/ootd/new/ootd?date=${date.toIso8601String()}');
              },
            );
          },
        ),
        GoRoute(
          path: '/ootd/new/ootd',
          builder: (context, state) {
            final dateStr = state.uri.queryParameters['date'] ?? DateTime.now().toIso8601String();
            final date = DateTime.parse(dateStr);
            final character = ref.read(userCharacterProvider)!;
            final existingRecord = state.extra as OotdRecord?;

            return OotdRecordScreen(
              userCharacter: character,
              recordDate: date,
              existingRecord: existingRecord,
              onSave: (newRecord) {
                ref.read(customRecordsProvider.notifier).update((state) {
                  final type = newRecord.brands['recordType'] ?? 'ootd';
                  final index = state.indexWhere((r) =>
                      r.date.year == newRecord.date.year &&
                      r.date.month == newRecord.date.month &&
                      r.date.day == newRecord.date.day &&
                      (r.brands['recordType'] ?? 'ootd') == type);
                  if (index != -1) {
                    final list = List<OotdRecord>.from(state);
                    list[index] = newRecord;
                    return list;
                  }
                  return [...state, newRecord];
                });
              },
            );
          },
        ),

        // 기억 상세 및 다이어리 템플릿
        GoRoute(
          path: '/memories/:memoryId',
          builder: (context, state) {
            final memoryId = state.pathParameters['memoryId'] ?? '0';
            return MemoryDetailPage(memoryId: memoryId);
          },
        ),
        GoRoute(
          path: '/memories/:memoryId/template-diary',
          builder: (context, state) {
            final memoryId = state.pathParameters['memoryId'] ?? '0';
            return MemoryDiaryTemplatePage(memoryId: memoryId);
          },
        ),
      ],
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('캐릭터 재설정'),
        content: const Text('캐릭터를 처음부터 다시 만들까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              ref.read(userCharacterProvider.notifier).state = null;
            },
            child: const Text(
              '초기화',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Riverpod 상태 변화를 감지하여 GoRouter 리프레시 노티파이어 트리거
    ref.listen(showSplashProvider, (a, b) => _refreshNotifier.notify());
    ref.listen(userCharacterProvider, (a, b) => _refreshNotifier.notify());

    return MaterialApp.router(
      title: 'ONMU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

// 라우터 갱신을 돕는 심플 노티파이어
class _RouterRefreshNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

// 탭 플레이스홀더 위젯
class _TabPlaceholder extends StatelessWidget {
  final String title;
  final String todoText;

  const _TabPlaceholder({required this.title, required this.todoText});

  @override
  Widget build(BuildContext context) {
    final textMain = const Color(0xFF3A2A23);
    final textSub = const Color(0xFF7A6258);
    final bgWarm = const Color(0xFFFFFDF9);

    return Scaffold(
      backgroundColor: bgWarm,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textMain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'TODO: $todoText',
              style: TextStyle(fontSize: 13, color: textSub),
            ),
          ],
        ),
      ),
    );
  }
}
