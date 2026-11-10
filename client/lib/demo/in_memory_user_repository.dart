import '../core/models/user.dart';
import '../core/repositories/user_repository.dart';
import 'demo_data.dart';

/// [UserRepository] backed by a fixed user. Pass `signedIn: null` to
/// simulate "nobody signed in".
class InMemoryUserRepository implements UserRepository {
  InMemoryUserRepository({this._signedIn = DemoData.asha});

  final User? _signedIn;

  @override
  Future<User?> currentUser() async => _signedIn;
}
