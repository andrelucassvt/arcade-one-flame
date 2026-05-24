import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
