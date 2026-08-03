String euro(num value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

String number(num value, {int digits = 2}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

String percentage(num value, {bool signed = false}) {
  final prefix = signed && value > 0 ? '+' : '';
  return '$prefix${number(value)} %';
}

String shortDate(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year}';
}

String dateTimeText(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${shortDate(value)} · ${two(value.hour)}:${two(value.minute)} Uhr';
}
