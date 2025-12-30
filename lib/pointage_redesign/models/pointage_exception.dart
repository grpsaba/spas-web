/// Types of errors that can occur in the pointage system
enum PointageErrorType {
  networkError,
  permissionDenied,
  dataNotFound,
  invalidInput,
  generationFailed,
  cacheError,
  queryError,
  timeout,
  cancelled,
  unknown;

  /// Get user-friendly error title
  String get title {
    switch (this) {
      case PointageErrorType.networkError:
        return 'Erreur de connexion';
      case PointageErrorType.permissionDenied:
        return 'Accès refusé';
      case PointageErrorType.dataNotFound:
        return 'Données introuvables';
      case PointageErrorType.invalidInput:
        return 'Données invalides';
      case PointageErrorType.generationFailed:
        return 'Échec de génération';
      case PointageErrorType.cacheError:
        return 'Erreur de cache';
      case PointageErrorType.queryError:
        return 'Erreur de requête';
      case PointageErrorType.timeout:
        return 'Délai d\'attente dépassé';
      case PointageErrorType.cancelled:
        return 'Opération annulée';
      case PointageErrorType.unknown:
        return 'Erreur inconnue';
    }
  }
}

/// Custom exception for pointage-related errors
class PointageException implements Exception {
  final PointageErrorType type;
  final String message;
  final String? technicalDetails;
  final StackTrace? stackTrace;
  final dynamic originalError;

  PointageException({
    required this.type,
    required this.message,
    this.technicalDetails,
    this.stackTrace,
    this.originalError,
  });

  /// Get user-friendly error message
  String get userMessage {
    switch (type) {
      case PointageErrorType.networkError:
        return 'Impossible de se connecter au serveur. Vérifiez votre connexion internet et réessayez.';
      case PointageErrorType.permissionDenied:
        return 'Vous n\'avez pas les permissions nécessaires pour effectuer cette action. Contactez votre administrateur.';
      case PointageErrorType.dataNotFound:
        return 'Les données demandées sont introuvables. Elles ont peut-être été supprimées.';
      case PointageErrorType.invalidInput:
        return message.isNotEmpty
            ? message
            : 'Les données saisies sont invalides. Veuillez vérifier et réessayer.';
      case PointageErrorType.generationFailed:
        return 'La génération du rapport a échoué. Veuillez réessayer ou contacter le support.';
      case PointageErrorType.cacheError:
        return 'Erreur lors de l\'accès au cache local. Les données seront rechargées depuis le serveur.';
      case PointageErrorType.queryError:
        return 'Erreur lors de la récupération des données. Veuillez réessayer.';
      case PointageErrorType.timeout:
        return 'L\'opération a pris trop de temps. Veuillez réessayer.';
      case PointageErrorType.cancelled:
        return message.isNotEmpty
            ? message
            : 'L\'opération a été annulée.';
      case PointageErrorType.unknown:
        return message.isNotEmpty
            ? message
            : 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
    }
  }

  /// Check if this error can be retried
  bool get isRetryable {
    switch (type) {
      case PointageErrorType.networkError:
      case PointageErrorType.timeout:
      case PointageErrorType.queryError:
      case PointageErrorType.cacheError:
      case PointageErrorType.generationFailed:
        return true;
      case PointageErrorType.permissionDenied:
      case PointageErrorType.dataNotFound:
      case PointageErrorType.invalidInput:
      case PointageErrorType.cancelled:
      case PointageErrorType.unknown:
        return false;
    }
  }

  /// Get suggested action for the user
  String? get suggestedAction {
    switch (type) {
      case PointageErrorType.networkError:
        return 'Vérifiez votre connexion internet et cliquez sur Réessayer.';
      case PointageErrorType.permissionDenied:
        return 'Contactez votre administrateur pour obtenir les permissions nécessaires.';
      case PointageErrorType.dataNotFound:
        return 'Actualisez la page ou vérifiez que les données existent toujours.';
      case PointageErrorType.invalidInput:
        return 'Vérifiez les données saisies et corrigez les erreurs.';
      case PointageErrorType.generationFailed:
        return 'Réessayez avec une période plus courte ou moins de filtres.';
      case PointageErrorType.cacheError:
        return 'Les données seront rechargées automatiquement.';
      case PointageErrorType.queryError:
        return 'Cliquez sur Réessayer ou simplifiez vos filtres.';
      case PointageErrorType.timeout:
        return 'Réessayez avec une période plus courte.';
      case PointageErrorType.cancelled:
        return null;
      case PointageErrorType.unknown:
        return 'Réessayez ou contactez le support si le problème persiste.';
    }
  }

  /// Create a network error
  factory PointageException.network({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.networkError,
      message: message ?? 'Erreur de connexion réseau',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create a permission denied error
  factory PointageException.permissionDenied({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.permissionDenied,
      message: message ?? 'Permission refusée',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create a data not found error
  factory PointageException.dataNotFound({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.dataNotFound,
      message: message ?? 'Données introuvables',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create an invalid input error
  factory PointageException.invalidInput({
    required String message,
    String? technicalDetails,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.invalidInput,
      message: message,
      technicalDetails: technicalDetails,
      stackTrace: stackTrace,
    );
  }

  /// Create a generation failed error
  factory PointageException.generationFailed({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.generationFailed,
      message: message ?? 'Échec de la génération du rapport',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create a cache error
  factory PointageException.cache({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.cacheError,
      message: message ?? 'Erreur de cache',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create a query error
  factory PointageException.query({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.queryError,
      message: message ?? 'Erreur de requête',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create a timeout error
  factory PointageException.timeout({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.timeout,
      message: message ?? 'Délai d\'attente dépassé',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create a cancelled error
  factory PointageException.cancelled({
    String? message,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.cancelled,
      message: message ?? 'Opération annulée',
      stackTrace: stackTrace,
    );
  }

  /// Create a report generation error
  factory PointageException.reportGeneration({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.generationFailed,
      message: message ?? 'Erreur lors de la génération du rapport',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Create an unknown error
  factory PointageException.unknown({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return PointageException(
      type: PointageErrorType.unknown,
      message: message ?? 'Erreur inconnue',
      originalError: originalError,
      stackTrace: stackTrace,
      technicalDetails: originalError?.toString(),
    );
  }

  /// Convert to a map for logging
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'message': message,
      'userMessage': userMessage,
      'technicalDetails': technicalDetails,
      'isRetryable': isRetryable,
      'suggestedAction': suggestedAction,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PointageException(type: ${type.name}, message: $message, retryable: $isRetryable)';
  }
}
