import 'package:flutter/material.dart';

import '../../shared/models/preference_profile.dart';
import '../preferences/preference_intro_page.dart';

class ProfilePreferenceScreen extends StatelessWidget {
  const ProfilePreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PreferenceIntroPage(profile: PreferenceProfile.mock());
  }
}
