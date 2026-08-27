import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../controllers/birthday_controller.dart';
import '../core/auth/firebase_auth_repository.dart';

/// Single composition root. Every dependency that the widget tree needs
/// must be obtainable from here. Widgets must not call `FooService()`
/// themselves — that means injecting into the tree via this class.
class AppDependencies {
  const AppDependencies._();

  static List<SingleChildWidget> providers() {
    return [
      ChangeNotifierProvider<BirthdayController>(
        create: (_) => BirthdayController()..loadBirthdays(),
      ),
      Provider<FirebaseAuthRepository>(
        create: (_) => FirebaseAuthRepository(),
      ),
    ];
  }
}
