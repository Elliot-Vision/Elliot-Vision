String euro(num value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

String number(num value, {int digits = 2}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

String percentage(num value, {bool signed = false}) {
  final prefix = signed && value > 0 ? '+' : '';
  return '$prefix${number(value)} %';
}

String shortDate(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year}';
}

String dateTimeText(DateTime value) {
  final local = value.toLocal();
  String two(int number) => number.toString().padLeft(2, '0');
  return '${shortDate(local)} · ${two(local.hour)}:${two(local.minute)} Uhr';
}
