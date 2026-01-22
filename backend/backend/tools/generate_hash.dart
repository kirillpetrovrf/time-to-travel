import 'package:bcrypt/bcrypt.dart';

void main() {
  final password = 'Test123!';
  final hash = BCrypt.hashpw(password, BCrypt.gensalt());
  print('Password hash for "$password":');
  print(hash);
}
