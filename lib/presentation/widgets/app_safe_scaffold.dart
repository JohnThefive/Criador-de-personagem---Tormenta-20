import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configurações centralizadas de barras do sistema (Edge-to-Edge e contraste).
abstract final class T20SystemUi {
  /// Estilo para telas com topo e barra de navegação escuros (Home, Arena, Mestre).
  static const SystemUiOverlayStyle estiloEscuro = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  /// Estilo para telas com topo e barra de navegação claros (Wizard de criação).
  static const SystemUiOverlayStyle estiloClaro = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  /// Estilo para a Ficha do Personagem (topo vermelho escuro, conteúdo claro).
  static const SystemUiOverlayStyle estiloFicha = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarContrastEnforced: false,
  );

  /// Habilita Edge-to-Edge globalmente para Android 15+ e configura estilo base.
  static Future<void> configurarEdgeToEdge() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(estiloEscuro);
  }
}

/// Retorna a margem inferior segura para listas roláveis, somando o padding base
/// ao inset inferior do sistema (barra de navegação de 3 botões ou gestos).
EdgeInsets appListPaddingWithBottomInset(
  BuildContext context,
  EdgeInsets base,
) {
  final bottomInset = MediaQuery.paddingOf(context).bottom;
  return base.copyWith(bottom: base.bottom + bottomInset);
}

/// Scaffold reutilizável que respeita consistentemente `SystemUiOverlayStyle`
/// e os insets de câmera, barra de status e barra de navegação do Android
/// (inclusive barra lateral no modo paisagem).
class AppSafeScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool resizeToAvoidBottomInset;
  final bool? safeTop;
  final bool safeBottom;
  final bool safeLeft;
  final bool safeRight;
  final SystemUiOverlayStyle? overlayStyle;

  const AppSafeScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset = true,
    this.safeTop,
    this.safeBottom = true,
    this.safeLeft = true,
    this.safeRight = true,
    this.overlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedStyle =
        overlayStyle ??
        (isDark ? T20SystemUi.estiloEscuro : T20SystemUi.estiloClaro);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: resolvedStyle,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        drawer: drawer,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar != null
            ? SafeArea(
                top: false,
                left: safeLeft,
                right: safeRight,
                bottom: safeBottom,
                child: bottomNavigationBar!,
              )
            : null,
        body: SafeArea(
          top: safeTop ?? (appBar == null),
          bottom: safeBottom,
          left: safeLeft,
          right: safeRight,
          child: body,
        ),
      ),
    );
  }
}

/// Container padrão para conteúdo de `showModalBottomSheet`.
///
/// Garante que o sheet respeite:
/// - `MediaQuery.viewInsetsOf(context).bottom` quando o teclado está aberto;
/// - `SafeArea` lateral e inferior (barra de 3 botões/gestos em retrato e paisagem);
/// - limite de altura em telas baixas / paisagem para nunca estourar.
class AppBottomSheetContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxHeightFactor;
  final bool scrollable;

  const AppBottomSheetContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 16),
    this.maxHeightFactor = 0.92,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;

    Widget content = Padding(
      padding: padding,
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(child: content);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsetsBottom),
        child: SafeArea(
          top: false,
          child: content,
        ),
      ),
    );
  }
}

/// Propaga o [SliverOverlapAbsorberHandle] do [NestedScrollView] para as abas
/// internas sem exigir que elas estejam sempre dentro de um [NestedScrollView]
/// (por exemplo, no modo paisagem lado a lado ou em testes isolados).
class NestedOverlapScope extends InheritedWidget {
  final SliverOverlapAbsorberHandle handle;

  const NestedOverlapScope({
    super.key,
    required this.handle,
    required super.child,
  });

  static SliverOverlapAbsorberHandle? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NestedOverlapScope>()
        ?.handle;
  }

  @override
  bool updateShouldNotify(NestedOverlapScope oldWidget) =>
      handle != oldWidget.handle;
}

/// Retorna [SliverOverlapInjector] quando dentro de [NestedOverlapScope];
/// caso contrário, retorna um sliver vazio.
Widget appNestedOverlapInjector(BuildContext context) {
  final handle = NestedOverlapScope.maybeOf(context);
  if (handle == null) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
  return SliverOverlapInjector(handle: handle);
}

/// Espaçador inferior de sliver que soma margem visual extra ao inset do
/// sistema (barra de navegação de 3 botões ou gestos do Android).
SliverToBoxAdapter appBottomSafeSliver(
  BuildContext context, {
  double extra = 20,
}) {
  return SliverToBoxAdapter(
    child: SizedBox(height: MediaQuery.paddingOf(context).bottom + extra),
  );
}

