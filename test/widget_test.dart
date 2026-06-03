import 'package:flutter_test/flutter_test.dart';
import 'package:kutral_ko/app/app.dart';
import 'package:kutral_ko/core/data/kutral_ko_repository.dart';

void main() {
  testWidgets('muestra dashboard inicial de Kutral Ko', (tester) async {
    await tester.pumpWidget(
      const KutralKoApp(
        repository: EmptyKutralKoRepository(),
        requireAuthentication: false,
      ),
    );

    expect(find.text('Kutral Ko'), findsOneWidget);
    expect(find.text('Saldo pendiente'), findsOneWidget);
    expect(find.text('Clientes activos'), findsOneWidget);
  });
}
