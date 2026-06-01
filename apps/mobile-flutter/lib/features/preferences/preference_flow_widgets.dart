import 'package:flutter/material.dart';

import '../../shared/onmu_design.dart';

class PreferencePageFrame extends StatelessWidget {
  final int currentStep;
  final int stepCount;
  final String title;
  final Widget child;
  final String buttonLabel;
  final VoidCallback? onNext;

  const PreferencePageFrame({
    super.key,
    required this.currentStep,
    required this.stepCount,
    required this.title,
    required this.child,
    required this.buttonLabel,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / stepCount;
    return Scaffold(
      backgroundColor: OnmuColors.bgDefault,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 24, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: '이전',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: OnmuColors.purpleSoft,
                            color: OnmuColors.pink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$currentStep/$stepCount',
                        style: const TextStyle(
                          color: OnmuColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 14),
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: OnmuColors.textMain,
                        fontSize: 27,
                        height: 1.22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: child,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: OnmuPrimaryButton(label: buttonLabel, onPressed: onNext),
            ),
          ],
        ),
      ),
    );
  }
}

class PreferenceOptionSection extends StatelessWidget {
  final String title;
  final String caption;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final bool isDislike;

  const PreferenceOptionSection({
    super.key,
    required this.title,
    required this.caption,
    required this.options,
    required this.selected,
    required this.onTap,
    this.isDislike = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: OnmuColors.textMain,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          caption,
          style: const TextStyle(
            color: OnmuColors.textSub,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return PreferenceChip(
              label: option,
              selected: selected.contains(option),
              isDislike: isDislike,
              onTap: () => onTap(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PreferenceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDislike;
  final VoidCallback onTap;

  const PreferenceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDislike,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isDislike ? OnmuColors.pink : OnmuColors.purple;
    final activeBg = isDislike ? OnmuColors.pinkSoft : OnmuColors.purpleSoft;
    return Material(
      color: selected ? activeBg : OnmuColors.bgWarm,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? activeColor : OnmuColors.lineSoft,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? activeColor : OnmuColors.textMuted,
                size: 18,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: OnmuColors.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PreferenceTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const PreferenceTextField({
    super.key,
    required this.label,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: OnmuColors.bgWarm,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OnmuColors.lineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: OnmuColors.purple),
        ),
      ),
    );
  }
}

void pushOnmuPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
