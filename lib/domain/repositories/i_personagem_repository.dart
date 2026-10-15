import '../entities/personagem/personagem.dart';

/// Contrato para persistência e recuperação de fichas de personagens.
///
/// Permite desacoplar as camadas de apresentação e lógica de negócios da implementação
/// concreta de armazenamento (arquivos no disco, SQLite, Hive, SharedPreferences ou nuvem).
abstract interface class IPersonagemRepository {
  /// Salva ou atualiza a ficha do personagem
  Future<void> salvar(Personagem p);

  /// Retorna todos os personagens persistidos
  Future<List<Personagem>> obterTodos();

  /// Busca um personagem específico pelo seu ID único
  Future<Personagem?> obterPorId(String id);

  /// Remove permanentemente o personagem com o ID especificado
  Future<void> excluir(String id);
}
