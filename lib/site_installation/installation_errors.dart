import 'installation_ui.dart' show installationReadableError;

/// Business failures already contain the instruction intended for the user.
/// Firebase failures are translated; Dart technical prefixes are removed.
String installationErrorMessage(Object error) =>
    installationReadableError(error);
