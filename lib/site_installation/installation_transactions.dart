import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore web passes callback errors through a JS Promise. Retain the Dart
/// error before that bridge so business failures keep their message and type.
Future<T> installationTransaction<T>(
    Future<T> Function(TransactionHandler<T>) run,
    TransactionHandler<T> action) async {
  Object? callbackError;
  StackTrace? callbackStack;
  try {
    return await run((transaction) async {
      callbackError = null;
      callbackStack = null;
      try {
        return await action(transaction);
      } catch (error, stack) {
        callbackError = error;
        callbackStack = stack;
        rethrow;
      }
    });
  } catch (_) {
    if (callbackError != null) {
      Error.throwWithStackTrace(callbackError!, callbackStack!);
    }
    rethrow;
  }
}
