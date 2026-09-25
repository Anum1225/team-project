import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user_model.dart';

/// Customer Authentication Service for HarvestHub.
/// Handles customer registration, secure login, role verification, and auth state.
class AuthService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _customAuth = auth,
        _customFirestore = firestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently logged in Firebase User.
  User? get currentUser => _auth.currentUser;

  /// UID of the current user, or null if not logged in.
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check whether any user is currently authenticated with Firebase.
  bool get isLoggedIn => _auth.currentUser != null;

  /// Collection reference to the top-level 'users' collection.
  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// 1. CUSTOMER REGISTRATION
  ///
  /// Registers a new customer using Firebase Authentication (Email/Password)
  /// and creates a corresponding Firestore profile document at users/{uid}.
  ///
  /// Required parameters according to the SRS:
  /// - [name]: Customer Full Name
  /// - [email]: Email Address
  /// - [password]: Password (min 6 characters)
  /// - [phone]: Mobile Phone Number
  /// - [address]: Physical/Delivery Address
  Future<UserModel> registerCustomer({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
  }) async {
    // 1. Basic validation
    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    final trimmedAddress = address.trim();

    if (trimmedName.isEmpty) {
      throw const AuthException('Full name is required.', code: 'invalid-name');
    }
    if (trimmedEmail.isEmpty) {
      throw const AuthException('Email address is required.', code: 'invalid-email');
    }
    if (password.length < 6) {
      throw const AuthException(
        'Password must be at least 6 characters.',
        code: 'weak-password',
      );
    }
    if (trimmedPhone.isEmpty) {
      throw const AuthException('Phone number is required.', code: 'invalid-phone');
    }
    if (trimmedAddress.isEmpty) {
      throw const AuthException('Address is required.', code: 'invalid-address');
    }

    try {
      // 2. Create user with Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Registration failed: No user returned.', code: 'user-null');
      }

      // Update Firebase Auth display name
      await user.updateDisplayName(trimmedName);

      // 3. Create customer document in Firestore at users/{uid}
      final now = DateTime.now();
      final customerModel = UserModel(
        userId: user.uid,
        name: trimmedName,
        email: trimmedEmail,
        phone: trimmedPhone,
        address: trimmedAddress,
        role: 'Customer', // Explicitly role = Customer as per SRS
        createdAt: now,
      );

      await _usersRef.doc(user.uid).set(customerModel.toMap());

      return customerModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on FirebaseException catch (e) {
      throw AuthException('Database error during registration: ${e.message}', code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred during registration: $e');
    }
  }

  /// 2. CUSTOMER LOGIN
  ///
  /// Authenticates a customer with email and password, verifies that the user
  /// possesses the "Customer" role in Firestore, and prevents Farmers/Admins
  /// from using customer login.
  Future<UserModel> loginCustomer({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw const AuthException('Email address is required.', code: 'invalid-email');
    }
    if (password.isEmpty) {
      throw const AuthException('Password is required.', code: 'missing-password');
    }

    try {
      // 1. Authenticate with Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Login failed: User record not found.', code: 'user-null');
      }

      // 2. Fetch the user's Firestore profile to verify role
      final doc = await _usersRef.doc(user.uid).get();

      if (!doc.exists) {
        // Sign out if no profile document exists
        await _auth.signOut();
        throw const AuthException(
          'Customer profile not found in database. Please register first.',
          code: 'profile-not-found',
        );
      }

      final profile = UserModel.fromFirestore(doc);

      // 3. Enforce Role: Must be "Customer"
      if (!profile.isCustomer) {
        // Sign out immediately so non-customer session is aborted
        await _auth.signOut();
        throw AuthException(
          'Access denied: This login is exclusively for Customers. Your account role is "${profile.role}".',
          code: 'wrong-role',
        );
      }

      return profile;
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } on FirebaseException catch (e) {
      throw AuthException('Database error during login: ${e.message}', code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('An unexpected error occurred during login: $e');
    }
  }

  /// 3. LOGOUT
  ///
  /// Signs out the currently authenticated user.
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } catch (e) {
      throw AuthException('Error during logout: $e');
    }
  }

  /// 4. GET CURRENT USER PROFILE
  ///
  /// Retrieves the current customer's Firestore profile as a [UserModel].
  Future<UserModel?> getCurrentUserProfile() async {
    final uid = currentUserId;
    if (uid == null) return null;

    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw ProfileException('Failed to load profile: $e');
    }
  }

  /// 5. GET USER ROLE
  ///
  /// Returns the role of the currently logged in user ('Customer', 'Farmer', 'Administrator', or null).
  Future<String?> getUserRole() async {
    final profile = await getCurrentUserProfile();
    return profile?.role;
  }

  /// 6. SEND PASSWORD RESET EMAIL
  ///
  /// Sends a password reset email to the provided address.
  Future<void> sendPasswordResetEmail(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      throw const AuthException('Email is required.', code: 'invalid-email');
    }
    try {
      await _auth.sendPasswordResetEmail(email: trimmed);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } catch (e) {
      throw AuthException('Failed to send password reset: $e');
    }
  }
}
