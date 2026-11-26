/// A single sequence shared by every company and department.
class InstallationNumbering {
  const InstallationNumbering(this.lastNumber);

  static const collection = 'installationOrderCounters';
  static const document = 'global';
  // Firestore integers must also remain exact in the web JavaScript runtime.
  static const maxNumber = 9007199254740991;
  final int lastNumber;

  factory InstallationNumbering.fromJson(Map<String, dynamic> data) {
    final value = data['lastNumber'];
    if (value is! int || value < 0 || value > maxNumber) {
      throw const FormatException('Le compteur des bons est invalide.');
    }
    return InstallationNumbering(value);
  }

  static int parseLastNumber(String text) {
    final value = text.trim();
    final number = int.tryParse(value);
    if (!RegExp(r'^[0-9]+$').hasMatch(value) ||
        number == null ||
        number < 0 ||
        number >= maxNumber) {
      throw const FormatException('Saisissez un numéro entier positif valide.');
    }
    return number;
  }

  int get nextNumber {
    if (lastNumber >= maxNumber) {
      throw StateError('La limite du compteur des bons est atteinte.');
    }
    return lastNumber + 1;
  }
}
