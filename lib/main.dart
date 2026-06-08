import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/session_viewmodel.dart';
import 'views/login_view.dart';
import 'views/home_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => SessionViewModel()..init()),
      ],
      child: MaterialApp(
        title: 'Clean Architecture MVVM',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.deepPurple,
        ),
        home: Consumer<SessionViewModel>(
          builder: (context, sessionVM, _) {
            if (!sessionVM.isInitialized) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (sessionVM.isLoggedIn) {
              return const HomeView();
            }
            return const LoginView();
          },
        ),
      ),
    );
  }
}