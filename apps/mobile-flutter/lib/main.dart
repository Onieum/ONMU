import 'package:flutter/material.dart';

void main() {
  runApp(const OnmuApp());
}

class OnmuApp extends StatelessWidget {
  const OnmuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ONMU',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7B4CF2),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PrototypeHomeScreen(),
    );
  }
}

class PrototypeHomeScreen extends StatelessWidget {
  const PrototypeHomeScreen({super.key});

  static const _steps = [
    PrototypeStep(
      title: '프로필 취향',
      description: '선호/비선호 태그와 가능 시간을 추천 입력값으로 연결',
      icon: Icons.person_outline,
    ),
    PrototypeStep(
      title: '약속 방',
      description: '참여자, 일정 후보, 실시간 상태를 하나의 room state로 관리',
      icon: Icons.groups_outlined,
    ),
    PrototypeStep(
      title: '장소 후보',
      description: '외부 API, 영업시간, 이동 시간, 리스크를 후보 점수로 표시',
      icon: Icons.place_outlined,
    ),
    PrototypeStep(
      title: '기록 카드',
      description: '사진과 캐릭터 요소를 약속 후 라이프로그로 저장',
      icon: Icons.photo_library_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ONMU'),
        actions: [
          IconButton(
            tooltip: '알림',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '약속을 만들고, 장소를 고르고, 기록으로 남기는 흐름',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 프로토타입은 4개 파트가 끊기지 않고 이어지는 얇은 사용자 여정을 목표로 합니다.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 24),
            for (final step in _steps) ...[
              PrototypeStepCard(step: step),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('약속 만들기'),
            ),
          ],
        ),
      ),
    );
  }
}

class PrototypeStep {
  const PrototypeStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  final String title;
  final String description;
  final IconData icon;
}

class PrototypeStepCard extends StatelessWidget {
  const PrototypeStepCard({required this.step, super.key});

  final PrototypeStep step;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(step.icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(step.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
