import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/my_profile.dart';
import '../repository/my_repository.dart';
import 'my_profile_controller.dart';

final settingsViewModelProvider =
    AsyncNotifierProvider<SettingsViewModel, SettingsState>(
      SettingsViewModel.new,
    );

class SettingsState {
  const SettingsState({
    required this.theme,
    required this.fontSize,
    required this.language,
    required this.quietHours,
    required this.cacheSize,
  });

  factory SettingsState.initial() {
    return const SettingsState(
      theme: '라이트 모드',
      fontSize: '보통',
      language: '한국어',
      quietHours: '오후 10:00 ~ 오전 8:00',
      cacheSize: '12.5 MB',
    );
  }

  final String theme;
  final String fontSize;
  final String language;
  final String quietHours;
  final String cacheSize;

  SettingsState copyWith({
    String? theme,
    String? fontSize,
    String? language,
    String? quietHours,
    String? cacheSize,
  }) {
    return SettingsState(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      language: language ?? this.language,
      quietHours: quietHours ?? this.quietHours,
      cacheSize: cacheSize ?? this.cacheSize,
    );
  }
}

class SettingsViewModel extends AsyncNotifier<SettingsState> {
  @override
  SettingsState build() {
    return SettingsState.initial();
  }

  void setTheme(String value) {
    _update((current) => current.copyWith(theme: value));
  }

  void setFontSize(String value) {
    _update((current) => current.copyWith(fontSize: value));
  }

  void setLanguage(String value) {
    _update((current) => current.copyWith(language: value));
  }

  void setQuietHours(String value) {
    _update((current) => current.copyWith(quietHours: value));
  }

  void clearCache() {
    _update((current) => current.copyWith(cacheSize: '0 MB'));
  }

  Future<void> updateProfileVisibility(
    MyProfile profile,
    ProfileVisibility visibility,
  ) async {
    await ref
        .read(myProfileControllerProvider)
        .saveProfile(profile.copyWith(visibility: visibility));
    ref.invalidate(myProfileProvider);
  }

  void _update(SettingsState Function(SettingsState current) update) {
    final current = state.value ?? SettingsState.initial();
    state = AsyncData(update(current));
  }
}
