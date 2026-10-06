import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:t20_creator/domain/services/data_services/call_poderes.dart';
import 'package:t20_creator/domain/services/data_services/call_armas.dart';
import 'package:t20_creator/domain/services/data_services/call_armaduras.dart';
import 'package:t20_creator/domain/services/data_services/call_racas.dart';
import 'package:t20_creator/domain/services/data_services/call_classes.dart';
import 'package:t20_creator/domain/services/data_services/call_origens.dart';
import 'package:t20_creator/domain/services/data_services/call_formas_selvagens.dart';
import 'package:t20_creator/domain/services/data_services/call_companheiros.dart';
import 'package:t20_creator/domain/services/data_services/call_efeitos_golpe_pessoal.dart';
import 'package:t20_creator/domain/services/data_services/call_regras_engenhocas.dart';
import 'package:t20_creator/domain/services/data_services/call_montaria_sagrada.dart';

// Importe seus arquivos
import 'presentation/controllers/home_cubit.dart';
import 'presentation/controllers/personagem_cubit.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BancoDeRacas.carregar();
  await BancoDeClasses.carregar();
  await BancoDeOrigens.carregar();
  await BancoDePoderes.carregar();
  await BancoDeArmas.carregar();
  await BancoDeArmaduras.carregar();
  await BancoDeFormasSelvagens.carregar();
  await BancoDeCompanheiros.carregar();
  await BancoDeEfeitosGolpePessoal.carregar();
  await BancoDeRegrasEngenhocas.carregar();
  await BancoDeRegrasMontariaSagrada.carregar();
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
        title: 'T20 - CRIADOR DE HEROIS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.red,
          useMaterial3: true,
          // Define a cor de fundo padrão do Scaffold se quiser
          scaffoldBackgroundColor: const Color(0xFFD32F2F),
        ),

        // home: define qual é a PRIMEIRA tela que o usuário vê.
        home: const HomeScreen(),
      ),
    );
  }
}
