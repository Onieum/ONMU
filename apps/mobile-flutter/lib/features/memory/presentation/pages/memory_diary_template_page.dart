import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/grid_background.dart';

class MemoryDiaryTemplatePage extends StatelessWidget {
  final String memoryId;

  const MemoryDiaryTemplatePage({super.key, required this.memoryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWarm,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textMain,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '다이어리 꾸미기 템플릿',
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GridBackground(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '원하는 디자인 템플릿을 선택하세요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '기록 스타일에 맞춰 어울리는 손글씨와 스티커 테마가 적용됩니다.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSub),
                ),
                const SizedBox(height: 24),

                // 템플릿 리스트 모의 레이아웃
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: [
                      _buildTemplateCard('다이어리 기본', '기본 아기자기 스티커 스타일', true),
                      _buildTemplateCard('깔끔 모던', '정돈된 선과 프레임', false),
                      _buildTemplateCard('스프링 북', '바인더 링 노트 테두리 장식', false),
                      _buildTemplateCard('레트로 빈티지', '빛바랜 노란 종이 텍스처', false),
                    ],
                  ),
                ),

                // 하단 저장 완료 버튼
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('다이어리 템플릿이 적용되어 최종 저장되었습니다!'),
                        ),
                      );
                      context.pop(); // Pop back to detail screen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('적용 완료'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String title, String desc, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDefault,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primaryPink : AppColors.lineSoft,
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primaryPink.withOpacity(0.12),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 90,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.bgWarm,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.lineSoft),
            ),
            child: const Icon(
              Icons.art_track_outlined,
              size: 36,
              color: AppColors.textSub,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}
