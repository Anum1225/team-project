/// Custom exceptions for HarvestHub Customer Backend
/// Provides clear, user-friendly error messages that can be displayed directly in the UI.
library;

/// Base exception for all HarvestHub backend operations.
class HarvestHubException implements Exception {
  final String message;
  final String? code;

  const HarvestHubException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Authentication-related exceptions (registration, login, role check, password update).
class AuthException extends HarvestHubException {
  const AuthException(super.message, {super.code});

  /// Factory to convert Firebase Auth error codes into friendly user messages.
  factory AuthException.fromFirebaseCode(String code, [String? defaultMsg]) {
    switch (code) {
      case 'invalid-email':
        return const AuthException(
          'The email address is not properly formatted.',
          code: 'invalid-email',
        );
      case 'user-disabled':
        return const AuthException(
          'This user account has been disabled. Please contact support.',
          code: 'user-disabled',
        );
      case 'user-not-found':
        return const AuthException(
          'No account found with this email address.',
          code: 'user-not-found',
        );
      case 'wrong-password':
      case 'invalid-credential':
        return const AuthException(
          'Incorrect email or password. Please try again.',
          code: 'wrong-password',
        );
      case 'email-already-in-use':
        return const AuthException(
          'An account already exists with this email address.',
          code: 'email-already-in-use',
        );
      case 'operation-not-allowed':
        return const AuthException(
          'Email/password accounts are not enabled. Please contact support.',
          code: 'operation-not-allowed',
        );
      case 'weak-password':
        return const AuthException(
          'The password is too weak. Please choose a stronger password (at least 6 characters).',
          code: 'weak-password',
        );
      case 'requires-recent-login':
        return const AuthException(
          'For security reasons, this operation requires recent authentication. Please log in again.',
          code: 'requires-recent-login',
        );
      case 'network-request-failed':
        return const AuthException(
          'Network connection error. Please check your internet connection.',
          code: 'network-request-failed',
        );
      case 'too-many-requests':
        return const AuthException(
          'Too many unsuccessful attempts. Please try again later.',
          code: 'too-many-requests',
        );
      default:
        return AuthException(
          defaultMsg ?? 'Authentication error occurred ($code).',
          code: code,
        );
    }
  }
}

/// Profile management exceptions (fetching, updating profile).
class ProfileException extends HarvestHubException {
  const ProfileException(super.message, {super.code});
}

/// Product-related exceptions (not found, query errors).
class ProductException extends HarvestHubException {
  const ProductException(super.message, {super.code});
}

/// Shopping cart exceptions (stock limitations, invalid quantities).
class CartException extends HarvestHubException {
  const CartException(super.message, {super.code});
}

/// Order creation and order history exceptions.
class OrderException extends HarvestHubException {
  const OrderException(super.message, {super.code});
}

/// Wishlist exceptions.
class WishlistException extends HarvestHubException {
  const WishlistException(super.message, {super.code});
}

/// Farmer favorite / follow exceptions.
class FavoriteException extends HarvestHubException {
  const FavoriteException(super.message, {super.code});
}
