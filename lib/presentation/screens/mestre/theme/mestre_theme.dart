import 'package:flutter/material.dart';

/// Paleta e Estilo do Painel do Mestre (Tormenta 20 - Android/Flutter)
/// Baseado na PARTE 0 — Fundação:
/// - Padrão Escuro "Vinho e Ouro"
/// - Alternativo Claro "Sangue e Marfim"
/// - Status Semânticos (Verde Online, Laranja Queimado Alerta/Erro, Cinza Offline)
class MestreCores {
  MestreCores._();

  // === ESCURO "Vinho e Ouro" (Padrão) ===
  static const Color escuroBackground = Color(0xFF0F0A0C);
  static const Color escuroSurface = Color(0xFF1A1114);
  static const Color escuroSurfaceContainer = Color(0xFF241519);
  static const Color escuroVinho = Color(0xFF6E1423);
  static const Color escuroVinhoPressed = Color(0xFF8E2236);
  static const Color escuroOuro = Color(0xFFF2C230);
  static const Color escuroOuroTexto = Color(0xFF1A1114);
  static const Color escuroOnSurface = Color(0xFFF3E9E6);
  static const Color escuroOnSurfaceVariant = Color(0xFFBFB0AD);
  static const Color escuroOutline = Color(0xFF4A3A3E);

  // === CLARO "Sangue e Marfim" ===
  static const Color claroPrimary = Color(0xFFB3121F);
  static const Color claroPrimaryContainer = Color(0xFFFBE3E4);
  static const Color claroBackground = Color(0xFFFFFFFF);
  static const Color claroSurface = Color(0xFFFAF7F6);
  static const Color claroOnSurface = Color(0xFF141012);
  static const Color claroOutline = Color(0xFFD9CFCE);
  static const Color claroPretoSuave = Color(0xFF141012);

  // === STATUS (O vermelho da marca NUNCA indica erro) ===
  static const Color statusOnlineEscuro = Color(0xFF3DDC97);
  static const Color statusOnlineClaro = Color(0xFF1E8E5A);

  static const Color statusAlertaEscuro = Color(0xFFFF7A45); // Laranja queimado
  static const Color statusAlertaClaro = Color(0xFFD9480F);

  static const Color statusOffline = Color(0xFF8E8385);
  static const Color statusReconectando = Color(0xFFE5A93B);

  // === TIPOGRAFIA E ESTILOS AUXILIARES ===
  static const TextStyle estiloTituloSerif = TextStyle(
    fontFamily: 'serif',
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  static const TextStyle estiloMono = TextStyle(
    fontFamily: 'monospace',
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}
