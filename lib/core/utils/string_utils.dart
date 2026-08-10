String? emptyToNull(String? value) {
  if (value == null) return null;
  final t = value.trim();
  return t.isEmpty ? null : t;
}
