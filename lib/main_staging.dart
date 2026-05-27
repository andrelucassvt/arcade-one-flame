import 'package:arcade_one/app/app.dart';
import 'package:arcade_one/bootstrap.dart';

Future<void> main() async {
  await bootstrap((prefs) => App(prefs: prefs));
}
