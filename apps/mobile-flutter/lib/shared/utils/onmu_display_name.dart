bool isDefaultOnmuDisplayName(String? value) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty) {
    return true;
  }
  return clean.toLowerCase() == 'onmu user' || clean == '사용자';
}

String resolveOnmuDisplayName(
  Iterable<String?> candidates, {
  required String fallback,
}) {
  for (final value in candidates) {
    final clean = value?.trim();
    if (clean != null && clean.isNotEmpty && !isDefaultOnmuDisplayName(clean)) {
      return clean;
    }
  }
  return fallback;
}
