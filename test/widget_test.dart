import 'package:family_hearth/src/app/family_hearth_app.dart';
import 'package:family_hearth/src/firebase/firebase_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('boots into the baby wall surface', (tester) async {
    await tester.pumpWidget(
      FamilyHearthApp(
        bootstrapFuture: Future.value(
          const FirebaseBootstrapResult.offline('test offline mode'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Grandma Mira'), findsOneWidget);
    expect(find.text('Grandpa Ivo'), findsOneWidget);
    expect(find.byTooltip('Open preview menu'), findsOneWidget);
  });
}
