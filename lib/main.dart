import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app/data/services/api_provider.dart';
import 'app/modules/map/bloc/map_bloc.dart';
import 'app/modules/video/bloc/video_bloc.dart';
import 'app/screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiProvider = ApiProvider();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => MapBloc(apiProvider: apiProvider),
        ),
        BlocProvider(create: (context) => VideoBloc(apiProvider: apiProvider)),
      ],
      child: MaterialApp(
        title: 'Baato Maps Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}
