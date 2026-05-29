import 'package:flutter/material.dart';
// 방금 신석님이 만든 공용 하단 탭바 위젯 불러오기
import '../../shared/widgets/onmu_bottom_nav_bar.dart';

// 신석님의 전용 구역: 마이페이지 - 취향 설정 화면
class ProfilePreferenceScreen extends StatelessWidget {
  const ProfilePreferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '내 취향 랩(Lab)',
          style: TextStyle(color: Color(0xFF3A2A23), fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xFF8B5CF6)),
            onPressed: () {
              print('취향 데이터 저장 버튼 클릭됨!');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. 내 픽셀 아바타'),
              const Placeholder(fallbackHeight: 120, color: Color(0xFFEAD8CC)), 
              const SizedBox(height: 32),

              _buildSectionTitle('2. 음식/메뉴 취향'),
              const Text('내가 좋아하는 음식 😋', style: TextStyle(fontSize: 14, color: Color(0xFFA9948A))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _mockOnmuChip('한식 🍚', isSelected: true),
                  _mockOnmuChip('일식 🍣', isSelected: false),
                  _mockOnmuChip('양식 🍝', isSelected: false),
                  _mockOnmuChip('매운 음식 스트레스 팍! 🌶️', isSelected: true),
                ],
              ),
              
              const SizedBox(height: 24),
              
              const Text('이건 꼭 빼주세요 🙅‍♂️', style: TextStyle(fontSize: 14, color: Color(0xFFA9948A))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _mockOnmuChip('맵찔이 🥵', isSelected: false),
                  _mockOnmuChip('오이 극혐 🥒', isSelected: true, isDislike: true),
                  _mockOnmuChip('고수/향신료 🌿', isSelected: false),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('3. 장소/분위기 취향'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _mockOnmuChip('조용한 곳 🤫', isSelected: true),
                  _mockOnmuChip('인스타 감성 📸', isSelected: false),
                  _mockOnmuChip('웨이팅 싫음 ⏳', isSelected: true, isDislike: true),
                ],
              ),
              const SizedBox(height: 32),

              _buildSectionTitle('4. 내 약속 시간표 (불가 일정)'),
              const Placeholder(fallbackHeight: 180, color: Color(0xFFEAD8CC)),
            ],
          ),
        ),
      ),
      // 🔥 여기에 방금 만든 하단 탭바가 조립됩니다! 🔥
      bottomNavigationBar: OnmuBottomNavBar(
        currentIndex: 4, // 4번 '마이' 탭 활성화
        onTap: (index) {
          print('$index 번째 탭이 눌렸습니다!'); 
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3A2A23)),
      ),
    );
  }

  Widget _mockOnmuChip(String label, {required bool isSelected, bool isDislike = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected 
            ? (isDislike ? const Color(0xFFFFE3E8) : const Color(0xFFEDE4FF)) 
            : Colors.white,
        border: Border.all(
          color: isSelected 
              ? (isDislike ? const Color(0xFFFF9CAD) : const Color(0xFFBDA4FF)) 
              : const Color(0xFFEAD8CC), 
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? const Color(0xFF3A2A23) : const Color(0xFFA9948A),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}