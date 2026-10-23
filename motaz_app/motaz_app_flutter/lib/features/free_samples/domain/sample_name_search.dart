String normalizeSampleName(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

bool matchesSampleName(String value, String query) {
  final normalizedQuery = normalizeSampleName(query);
  if (normalizedQuery.isEmpty) return false;

  final words = normalizeSampleName(value).split(' ');
  return normalizedQuery
      .split(' ')
      .every(
        (term) => words.any((word) => word.startsWith(term)),
      );
}
