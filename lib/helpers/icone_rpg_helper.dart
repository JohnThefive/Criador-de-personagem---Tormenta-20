import 'package:flutter/widgets.dart';
import 'package:fluttericon/rpg_awesome_icons.dart';

/// Utilitário para mapear chaves de strings vindas de JSON em IconData do RpgAwesome
class IconeRpgHelper {
  IconeRpgHelper._();

  static const Map<String, IconData> _icones = {
    // Raças
    'axe': RpgAwesome.axe,
    'clover': RpgAwesome.clover,
    'feathered_wing': RpgAwesome.feathered_wing,
    'wrench': RpgAwesome.wrench,
    'horns': RpgAwesome.horns,
    'aura': RpgAwesome.aura,
    'cog': RpgAwesome.cog,
    'dice_six': RpgAwesome.dice_six,
    'clockwork': RpgAwesome.clockwork,
    'venomous_snake': RpgAwesome.venomous_snake,
    'fairy': RpgAwesome.fairy,
    'angel_wings': RpgAwesome.angel_wings,
    'batwings': RpgAwesome.batwings,
    'dinosaur': RpgAwesome.dinosaur,
    'player': RpgAwesome.player,
    'tentacle': RpgAwesome.tentacle,
    'skull': RpgAwesome.skull,
    'trident': RpgAwesome.trident,

    // Classes T20
    'crystal_ball': RpgAwesome.crystal_ball,
    'harp': RpgAwesome.ocarina,
    'ocarina': RpgAwesome.ocarina,
    'saber-and-pistol': RpgAwesome.crossed_sabres,
    'saber_and_pistol': RpgAwesome.crossed_sabres,
    'crossed_sabres': RpgAwesome.crossed_sabres,
    'crossed_pistols': RpgAwesome.crossed_pistols,
    'crossbow': RpgAwesome.crossbow,
    'knight_helmet': RpgAwesome.knight_helmet,
    'ankh': RpgAwesome.ankh,
    'leaf': RpgAwesome.leaf,
    'crossed_swords': RpgAwesome.crossed_swords,
    'broadsword': RpgAwesome.broadsword,
    'gears': RpgAwesome.gears,
    'cloak_and_dagger': RpgAwesome.cloak_and_dagger,
    'daggers': RpgAwesome.daggers,
    'crush': RpgAwesome.crush,
    'crown': RpgAwesome.crown,
    'shield': RpgAwesome.shield,

    // Ícones adicionais úteis para futuras classes, raças e homebrew
    'dragon': RpgAwesome.dragon,
    'dragon_breath': RpgAwesome.dragon_breath,
    'fire': RpgAwesome.fire,
    'ice_cube': RpgAwesome.ice_cube,
    'lightning': RpgAwesome.lightning,
    'water_drop': RpgAwesome.water_drop,
    'sun_symbol': RpgAwesome.sun_symbol,
    'moon_sun': RpgAwesome.moon_sun,
    'heart': RpgAwesome.hearts,
    'book': RpgAwesome.book,
    'potion': RpgAwesome.potion,
    'gem': RpgAwesome.gem,
    'cat': RpgAwesome.cat,
    'wolf_head': RpgAwesome.wolf_head,
  };

  /// Retorna o IconData correspondente à chave informada no JSON.
  /// Caso a chave não seja encontrada, retorna `RpgAwesome.player` como fallback seguro.
  static IconData obterIcone(String? chave) {
    if (chave == null || chave.isEmpty) {
      return RpgAwesome.player;
    }
    final normalizada = chave.toLowerCase().trim();
    return _icones[normalizada] ??
        _icones[normalizada.replaceAll('-', '_')] ??
        RpgAwesome.player;
  }

  /// Retorna todas as chaves disponíveis para seleção (ideal para criação de raças e classes homebrew)
  static List<String> get chavesDisponiveis => _icones.keys.toList();
}
