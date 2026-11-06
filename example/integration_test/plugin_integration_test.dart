import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_live_beauty/flutter_live_beauty.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final String? version = await FlutterLiveBeauty.getPlatformVersion();
    expect(version?.isNotEmpty, true);
  });
}
