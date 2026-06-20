import '../l10n/app_localizations.dart';

/// Человекочитаемые сообщения по кодам Firebase Auth.
class AuthErrorMessages {
  static String message(
    AppLocalizations l10n,
    String code, {
    bool passwordReset = false,
  }) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return l10n.invalidLoginCredentials;
      case 'user-not-found':
        return passwordReset ? l10n.authUserNotFound : l10n.invalidLoginCredentials;
      case 'too-many-requests':
        return l10n.tooManyRequests;
      case 'invalid-email':
        return l10n.invalidEmail;
      case 'user-disabled':
        return l10n.authUserDisabled;
      case 'network-request-failed':
        return l10n.authNetworkError;
      case 'operation-not-allowed':
        return l10n.authOperationNotAllowed;
      case 'api-key-not-valid':
      case 'invalid-api-key':
        return l10n.authInvalidApiKey;
      case 'app-not-authorized':
        return l10n.authAppNotAuthorized;
      case 'internal-error':
        return l10n.authInternalError;
      case 'expired-action-code':
      case 'invalid-action-code':
        return passwordReset ? l10n.invalidResetLink : l10n.authInternalError;
      case 'smtp-not-configured':
      case 'email-send-failed':
      case 'link-generation-failed':
      case 'link-parse-failed':
        return l10n.authPasswordResetFailed;
      case 'profile-not-found':
        return l10n.authProfileNotFound;
      case 'unauthorized-continue-uri':
      case 'invalid-continue-uri':
        return passwordReset ? l10n.authPasswordResetFailed : l10n.authInternalError;
      case 'unknown_error':
      case 'unknown':
        return passwordReset
            ? l10n.authPasswordResetFailed
            : l10n.errorWithDetail(code);
      default:
        if (passwordReset &&
            (code.startsWith('error-code:') ||
                RegExp(r'^-?\d+$').hasMatch(code))) {
          return l10n.authPasswordResetFailed;
        }
        if (code.startsWith('error-code:')) {
          return l10n.errorWithDetail(code.substring('error-code:'.length));
        }
        if (RegExp(r'^-?\d+$').hasMatch(code)) {
          return l10n.errorWithDetail(code);
        }
        return l10n.errorWithDetail(code);
    }
  }
}
