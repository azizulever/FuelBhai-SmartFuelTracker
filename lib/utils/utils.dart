import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('yyyy-MM-dd').format(date);
}

bool isValidInput(String input) {
  if (input.isEmpty) return false;
  final number = num.tryParse(input);
  return number != null && number > 0;
}
