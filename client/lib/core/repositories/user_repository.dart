import '../models/user.dart';

/// Where the signed-in user comes from (demo data today, the server later).
abstract interface class UserRepository {
  /// The signed-in user, or null when nobody is signed in.
  Future<User?> currentUser();
}
