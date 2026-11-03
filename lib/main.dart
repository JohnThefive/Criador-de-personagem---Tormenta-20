import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/services/data_services/catalogo_service.dart';

// Importe seus arquivos
import 'presentation/controllers/home_controller/home_cubit.dart';
import 'presentation/controllers/ficha_controller/personagem_cubit.dart';
import 'presentation/screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CatalogoService.carregarTodos();
  runApp(const T20App());
}

class T20App extends StatelessWidget {
  const T20App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // O HomeCubit fica vivo o tempo todo para segurar a lista
        BlocProvider(create: (context) => HomeCubit()),

        // O PersonagemCubit pode ser criado aqui ou na hora de navegar
        BlocProvider(create: (context) => PersonagemCubit()),
      ],
      child: MaterialApp(
        title: 'T20 - Criador de heróis',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          useMaterial3: true,
          // Define a cor de fundo padrão do Scaffold para as telas existentes
          scaffoldBackgroundColor: const Color(0xFFD32F2F),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            showDragHandle: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFFD32F2F),
                width: 1.5,
              ),
            ),
          ),
        ),

        // home: define qual é a PRIMEIRA tela que o usuário vê.
        home: const HomeScreen(),
      ),
    );
  }
}
