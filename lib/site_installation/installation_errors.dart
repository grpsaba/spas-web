/// Business failures already contain the instruction intended for the user.
String installationErrorMessage(Object error) {
  if (error is StateError) return error.message;
  if (error is FormatException) return error.message;
  return error.toString();
}
