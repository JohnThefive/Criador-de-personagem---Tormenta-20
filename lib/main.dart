import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Importe seus arquivos
import 'presentation/controllers/home_cubit.dart';
import 'presentation/controllers/personagem_cubit.dart';
import 'presentation/screens/home_screen.dart'; // <--- A tela vermelha está aqui

void main() {
  runApp(const T20App());
}

class T20App extends StatelessWidget {
  const T20App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      // Aqui nós "injetamos" os cérebros no app inteiro
      providers: [
        // O HomeCubit fica vivo o tempo todo para segurar a lista
        BlocProvider(create: (context) => HomeCubit()),
        
        // O PersonagemCubit pode ser criado aqui ou na hora de navegar
        BlocProvider(create: (context) => PersonagemCubit()),
      ],
      child: MaterialApp(
        title: 'T20 - CRIADOR DE HEROIS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          useMaterial3: true,
          // Define a cor de fundo padrão do Scaffold se quiser
          scaffoldBackgroundColor: const Color(0xFFD32F2F), 
        ),
        
        // AQUI É O PULO DO GATO:
        // home: define qual é a PRIMEIRA tela que o usuário vê.
        home: const HomeScreen(), 
      ),
    );
  }
}