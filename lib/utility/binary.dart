String bytesToReadable(int bytes, {bool useBinaryPrefixes = false}) {
  int divisor = useBinaryPrefixes ? 1024 : 1000;
  String unit = useBinaryPrefixes ? 'B' : 'B';
  List<String> prefixes =
      useBinaryPrefixes ? ['Ki', 'Mi', 'Gi', 'Ti', 'Pi', 'Ei', 'Zi', 'Yi'] : ['K', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y'];

  double value = bytes.toDouble();

  for (var prefix in prefixes) {
    value /= divisor;
    if (value < divisor) {
      unit = '$prefix$unit';
      break;
    }
  }

  return '${value.toStringAsFixed(2)} $unit';
}
