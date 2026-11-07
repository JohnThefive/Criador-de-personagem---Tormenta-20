import 'package:flutter/material.dart';
import 'package:t20_creator/domain/entities/habilidades/modelos_resistencia_efeito.dart';
import 'package:t20_creator/domain/services/habilidades_services/imunidade_service.dart';

/// Painel do Mestre: Visão Geral de Resistências, Imunidades e Objetos (R50–R58).
///
/// Permite ao Mestre inspecionar em tempo real:
/// 1. Bônus de resistência de cada criatura (Fortitude, Reflexos, Vontade).
/// 2. Imunidades inatas (Construtos, Mortos-vivos, Mente nula) e adquiridas.
/// 3. Objetos no mapa (Mundano solto / Carregado / Mágico).
/// 4. Status de ilusões desacreditadas.
class PainelResistenciaMestre extends StatelessWidget {
  final List<Criatura> criaturas;
  final List<ItemObjeto> objetos;
  final Set<String> desacreditadosIlusao;
  final void Function(Criatura criatura)? onSolicitarTesteCriatura;
  final void Function(ItemObjeto objeto)? onSolicitarTesteObjeto;

  const PainelResistenciaMestre({
    super.key,
    required this.criaturas,
    this.objetos = const [],
    this.desacreditadosIlusao = const {},
    this.onSolicitarTesteCriatura,
    this.onSolicitarTesteObjeto,
  });

  @override
  Widget build(BuildContext context) {
    const imunidadeService = ImunidadeService();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.shield, color: Colors.amberAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Visão do Mestre: Resistências e Imunidades',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 20),
          // Seção 1: Criaturas
          const Text(
            'CRIATURAS NO MAPA',
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          if (criaturas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhuma criatura registrada.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: criaturas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final c = criaturas[index];
                final inatas = imunidadeService.calcularImunidadesInatas(
                  c.tipoCriatura,
                  inteligencia: c.inteligencia,
                );
                final todasImunidades = imunidadeService.obterImunidadesTotais(c);
                final desacreditou = desacreditadosIlusao.contains(c.id);

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: desacreditou ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white12,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.nome,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    c.tipoCriatura.name,
                                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                                  ),
                                ),
                                if (desacreditou) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.cyan.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Ilusão Revelada',
                                      style: TextStyle(color: Colors.cyanAccent, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'FORT +${c.bonusResistencia.fortitude} | REF +${c.bonusResistencia.reflexos} | VON +${c.bonusResistencia.vontade}'
                              '${c.temInteligenciaNula ? " | (Mente Nula)" : ""}',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                            if (todasImunidades.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: todasImunidades.map((im) {
                                  final ehInata = inatas.contains(im);
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: ehInata ? Colors.purple.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Imune: ${im.name}',
                                      style: TextStyle(
                                        color: ehInata ? Colors.purpleAccent : Colors.lightBlueAccent,
                                        fontSize: 9,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (onSolicitarTesteCriatura != null)
                        IconButton(
                          tooltip: 'Solicitar Teste',
                          icon: const Icon(Icons.casino, color: Colors.amberAccent, size: 20),
                          onPressed: () => onSolicitarTesteCriatura!(c),
                        ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
          // Seção 2: Objetos
          const Text(
            'OBJETOS NO MAPA',
            style: TextStyle(
              color: Colors.amberAccent,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          if (objetos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nenhum objeto independente registrado.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: objetos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final obj = objetos[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  obj.nome,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: obj.magico ? Colors.amber.withValues(alpha: 0.2) : Colors.white10,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    obj.magico ? 'Mágico' : 'Mundano',
                                    style: TextStyle(
                                      color: obj.magico ? Colors.amberAccent : Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              obj.estaCarregado
                                  ? 'Carregado por: ${obj.carregadoPor} (Imune a dano de área por padrão)'
                                  : 'Objeto Solto no Chão (Falha automática em testes)',
                              style: TextStyle(
                                color: obj.estaCarregado ? Colors.greenAccent : Colors.orangeAccent,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onSolicitarTesteObjeto != null)
                        IconButton(
                          tooltip: 'Testar Objeto',
                          icon: const Icon(Icons.casino, color: Colors.amberAccent, size: 20),
                          onPressed: () => onSolicitarTesteObjeto!(obj),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
