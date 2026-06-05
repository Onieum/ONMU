import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/preference_profile.dart';
import '../../shared/providers/state_providers.dart';
import '../preferences/preference_intro_page.dart';

class ProfilePreferenceScreen extends ConsumerWidget {
  const ProfilePreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile =
        ref.watch(preferenceProfileProvider) ?? PreferenceProfile.empty();

    return PreferenceIntroPage(profile: profile);
  }
}
