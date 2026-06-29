import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

enum FirebaseBootstrapStatus { ready, offline }

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult({
    required this.status,
    required this.message,
    this.userId,
  });

  const FirebaseBootstrapResult.ready({String? userId})
    : this(
        status: FirebaseBootstrapStatus.ready,
        message: 'Firebase connected',
        userId: userId,
      );

  const FirebaseBootstrapResult.offline(String message)
    : this(status: FirebaseBootstrapStatus.offline, message: message);

  final FirebaseBootstrapStatus status;
  final String message;
  final String? userId;

  bool get isReady => status == FirebaseBootstrapStatus.ready;
}

class FirebaseBootstrap {
  Future<FirebaseBootstrapResult> start() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final auth = FirebaseAuth.instance;
      final user = auth.currentUser;

      return FirebaseBootstrapResult.ready(userId: user?.uid);
    } on FirebaseException catch (error) {
      return FirebaseBootstrapResult.offline(
        'Firebase is unavailable (${error.code}). Cloud services are offline.',
      );
    } on Object catch (error) {
      return FirebaseBootstrapResult.offline(
        'Firebase startup failed. Cloud services are offline. $error',
      );
    }
  }
}
