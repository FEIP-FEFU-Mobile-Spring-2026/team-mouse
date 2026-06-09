String formatPrice(int kopecks) {
  final rubles = kopecks ~/ 100;
  final s = rubles.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buffer.write(' ');
    }
    buffer.write(s[i]);
  }
  return '${buffer.toString()} ₽';
}
