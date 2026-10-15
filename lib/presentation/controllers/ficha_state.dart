import 'package:equatable/equatable.dart';
import '../../domain/entities/personagem/personagem.dart';

class FichaState extends Equatable {
  final Personagem personagem;
  final bool salvando;
  final String? mensagemErro;
  final String? mensagemSucesso;

  const FichaState({
    required this.personagem,
    this.salvando = false,
    this.mensagemErro,
    this.mensagemSucesso,
  });

  FichaState copyWith({
    Personagem? personagem,
    bool? salvando,
    String? mensagemErro,
    String? mensagemSucesso,
    bool anularErro = false,
    bool anularSucesso = false,
  }) {
    return FichaState(
      personagem: personagem ?? this.personagem,
      salvando: salvando ?? this.salvando,
      mensagemErro: anularErro ? null : (mensagemErro ?? this.mensagemErro),
      mensagemSucesso: anularSucesso
          ? null
          : (mensagemSucesso ?? this.mensagemSucesso),
    );
  }

  @override
  List<Object?> get props => [
    personagem,
    salvando,
    mensagemErro,
    mensagemSucesso,
  ];
}
