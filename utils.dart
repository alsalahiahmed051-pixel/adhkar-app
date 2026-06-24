import 'dart:math';

final _rand = Random();

String generateId() =>
    '${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}${_rand.nextInt(999999).toRadixString(36)}';

/// Excludes 0/O/1/I/L — easy to read aloud, hard to mistype when sharing a code.
const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

String generateShareCode() =>
    List.generate(6, (_) => _codeAlphabet[_rand.nextInt(_codeAlphabet.length)]).join();

String normalizeArabic(String s) {
  return s
      .replaceAll(RegExp(r'[\u0610-\u061A\u064B-\u065F\u06D6-\u06ED\u0670]'), '')
      .replaceAll(RegExp(r'[إأآا]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ـ', '')
      .toLowerCase()
      .trim();
}
