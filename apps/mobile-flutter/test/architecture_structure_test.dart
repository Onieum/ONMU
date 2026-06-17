import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature page entrypoints live under presentation pages', () {
    const legacyEntrypoints = [
      'lib/features/auth/login_page.dart',
      'lib/features/character/character_start_page.dart',
      'lib/features/group/group_list_page.dart',
      'lib/features/home/home_page.dart',
      'lib/features/memory/memory_detail_page.dart',
      'lib/features/my/my_page.dart',
      'lib/features/onboarding/onboarding_hub_page.dart',
      'lib/features/ootd/ootd_list_page.dart',
      'lib/features/place/place_candidate_page.dart',
      'lib/features/preferences/preference_intro_page.dart',
    ];

    for (final path in legacyEntrypoints) {
      expect(File(path).existsSync(), isFalse, reason: '$path must be removed');
    }
  });

  test('shared design barrel is replaced by canonical widgets and theme', () {
    expect(File('lib/shared/onmu_design.dart').existsSync(), isFalse);

    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains('shared/onmu_design.dart')),
        reason: '${file.path} imports shared/onmu_design.dart',
      );
    }
  });

  test('router does not call repositories directly', () {
    final source = File('lib/core/routing/app_router.dart').readAsStringSync();

    for (final forbidden in [
      'recordRepositoryProvider',
      'characterRepositoryProvider',
      'myRepositoryProvider',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });

  test('my page delegates tabs, editors, and settings to part files', () {
    final source = File(
      'lib/features/my/presentation/pages/my_page.dart',
    ).readAsStringSync();

    expect(source.split('\n'), hasLength(lessThan(360)));
    for (final forbidden in [
      'class _FriendsTab',
      'class _FriendProfilePage',
      'class _ProfileDetailPage',
      'class _ProfileSectionEditPage',
      'class _ProfileEditPage',
      'class _SettingsPage',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
  });

  test('ootd list delegates timeline sheet content to part files', () {
    final source = File(
      'lib/features/ootd/presentation/pages/ootd_list_page.dart',
    ).readAsStringSync();

    expect(source.split('\n'), hasLength(lessThan(950)));
    expect(source, isNot(contains('class _TimelineBottomSheetContent')));
  });

  test('daily record form delegates result rendering to part files', () {
    final source = File(
      'lib/features/ootd/presentation/pages/daily_record_screen.dart',
    ).readAsStringSync();

    expect(source.split('\n'), hasLength(lessThan(1250)));
    expect(source, isNot(contains('class DailyRecordResultScreen')));
    expect(source, isNot(contains('class _DiaryResultLayout')));
  });

  test('daily record screens do not contain mojibake copy', () {
    const pagePaths = [
      'lib/features/ootd/presentation/pages/daily_record_screen.dart',
      'lib/features/ootd/presentation/pages/daily_record_result.dart',
    ];
    final mojibakePattern = RegExp(r'[筌繹醫揶疫熬夷]|뮎|퀡|쏙옙|占');

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(contains(mojibakePattern)),
        reason: '$path contains broken Korean copy',
      );
    }
  });

  test('plan create page delegates repository work to view model layer', () {
    final source = File(
      'lib/features/plan/presentation/pages/plan_create_page.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('planRepositoryProvider')));
    expect(source, isNot(contains('groupRepositoryProvider')));
  });

  test('mutation heavy pages delegate repository work to controllers', () {
    const pagePaths = [
      'lib/features/my/presentation/pages/my_page.dart',
      'lib/features/onboarding/presentation/pages/onboarding_hub_page.dart',
      'lib/features/preferences/preference_summary_page.dart',
      'lib/features/memory/presentation/pages/memory_detail_page.dart',
      'lib/features/ootd/presentation/pages/daily_record_edit_screen.dart',
    ];

    for (final path in pagePaths) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        isNot(contains(RegExp(r'\w+RepositoryProvider'))),
        reason: '$path should use a ViewModel/controller for repositories',
      );
    }
  });
}
