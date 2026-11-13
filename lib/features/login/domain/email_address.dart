/// Basic format validation shared by the form and authentication repositories.
bool isValidEmailAddress(String value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim());
