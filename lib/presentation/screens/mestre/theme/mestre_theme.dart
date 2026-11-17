import 'package:flutter/material.dart';
import '../../../../domain/entities/mestre/modelos_mestre.dart';

/// Paleta e Estilo do Painel do Mestre (Tormenta 20 - Android/Flutter)
/// Baseado na PARTE 0 — Fundação:
/// - Padrão Escuro "Vinho e Ouro"
/// - Status Semânticos (Verde Online, Laranja Queimado Alerta/Erro, Cinza Offline)
class MestreCores {
  MestreCores._();

  // === ESCURO "Vinho e Ouro" (Padrão) ===
  static const Color escuroBackground = Color(0xFF0F0A0C);
  static const Color escuroSurface = Color(0xFF1A1114);
  static const Color escuroSurfaceContainer = Color(0xFF241519);
  static const Color escuroVinho = Color(0xFF6E1423);
  static const Color escuroOuro = Color(0xFFF2C230);
  static const Color escuroOuroTexto = Color(0xFF1A1114);
  static const Color escuroOnSurface = Color(0xFFF3E9E6);
  static const Color escuroOnSurfaceVariant = Color(0xFFBFB0AD);
  static const Color escuroOutline = Color(0xFF4A3A3E);

  // === STATUS (O vermelho da marca NUNCA indica erro) ===
  static const Color statusOnlineEscuro = Color(0xFF3DDC97);
  static const Color statusAlertaEscuro = Color(0xFFFF7A45); // Laranja queimado
  static const Color statusOffline = Color(0xFF8E8385);

  // === TIPOGRAFIA E ESTILOS AUXILIARES ===
  static const TextStyle estiloMono = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );

  /// Cor base de fundo associada a cada preset temático de mapa.
  static Color corFundoPreset(PresetFundoMapa preset) {
    switch (preset) {
      case PresetFundoMapa.florestaArton:
        return const Color(0xFF132A13);
      case PresetFundoMapa.tavernaMadeira:
        return const Color(0xFF38220F);
      case PresetFundoMapa.desertoHalakTur:
        return const Color(0xFF4A3B18);
      case PresetFundoMapa.areaTormenta:
        return const Color(0xFF3F0B18);
      case PresetFundoMapa.masmorraPedra:
      case PresetFundoMapa.imagemCustomizada:
        return const Color(0xFF1C1917);
    }
  }

  /// Tema Material 3 compartilhado com a HomeScreen para manter coesão visual.
  static final ThemeData homeStyleTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFFD32F2F),
      brightness: Brightness.dark,
    ),
  );
}
