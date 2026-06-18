bool isDefaultOnmuDisplayName(String? value) {
  return value?.trim().toLowerCase() == 'onmu user';
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
