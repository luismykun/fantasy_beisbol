import 'package:fantasy_mobile/src/app.dart';
import 'package:fantasy_mobile/src/bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const FantasyMobileApp());
}
