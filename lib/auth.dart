import 'package:firebase_auth/firebase_auth.dart';
import 'package:better_health/admin_init.dart';
import 'package:better_health/api/api_client.dart';
import 'package:logging/logging.dart';

class Auth {
  final _firebaseAuth = AdminInit().firebaseAuth;
  User? get currentUser => _firebaseAuth.currentUser;
  final Logger _logger = Logger('Auth');

  Stream<User?> get authstateChanges => _firebaseAuth.authStateChanges();

  Future<void> signInwithEmailAndPassword({
    required String email,
    required String password,
    void Function()? onSuccess,
  }) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.post(
        '/login',
        {'email': email, 'password': password},
        data: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        apiClient.addAuthHeader(token);
        onSuccess!();
      } else {
        _logger.warning(response.data['message']);
      }
    } catch (e) {
      _logger.warning('Error: $e');
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
    required String confirmationPassword,
    void Function()? onSuccess,
  }) async {
    try {
      final apiClient = ApiClient();
      final newUser = {
        'username': username,
        'email': email,
        'password': password,
        'confirmationPassword': confirmationPassword,
      };
      final response = await apiClient.post(
        '/users/new',
        newUser,
        data: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 201) {
        final token = await FirebaseAuth.instance.currentUser?.getIdToken();
        apiClient.addAuthHeader(token!);
        if (onSuccess != null) {
          onSuccess();
        }
      } else if (response.statusCode == 400) {
        _logger.warning(response.data.message);
      }
    } catch (e) {
      _logger.warning('Error: $e');
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
