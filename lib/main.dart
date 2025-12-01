import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/local_storage.dart';
import 'controllers/expedition_controller.dart';
import 'controllers/logbook_controller.dart';
import 'views/auth/splash_page.dart';
import 'views/auth/login_page.dart';
import 'views/home/home_wrapper.dart';
import 'models/expedition_model.dart';
import 'models/logbook_model.dart';
import 'package:intl/date_symbol_data_local.dart';
import'utils/notification_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Daftarkan semua adapter model
  Hive.registerAdapter(ExpeditionModelAdapter());
  await Hive.openBox<ExpeditionModel>('expeditions');
  Hive.registerAdapter(LogbookModelAdapter());
  await Hive.openBox<LogbookModel>('logbooks_box');

  // Initialize services
  await Future.wait([
    LocalStorageService.init(),
    initializeDateFormatting('id_ID', null),
    SharedPreferences.getInstance(), // Initialize SharedPreferences
  ]);

  // Register Hive Adapters
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(ExpeditionModelAdapter());
  }

  //register notifikasi
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper.initialize();
  await NotificationHelper.showNotification(
  title: 'MAPALA Adventure Logbook',
  body: 'Catat setiap langkah, abadikan setiap perjalanan',
);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpeditionController()),
        ChangeNotifierProvider(create: (_) => LogbookController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(builder: (_) => const SplashPage());
            case '/home':
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => HomeWrapper(
                  username: args['username'],
                  leaderId: args['leaderId'],
                ),
              );
            case '/login':
              return MaterialPageRoute(builder: (_) => const LoginPage());
            default:
              return MaterialPageRoute(builder: (_) => const SplashPage());
          }
        },
      ),
    );
  }
}