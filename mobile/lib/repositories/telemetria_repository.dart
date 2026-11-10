import 'dart:async';
import '../datasources/telemetria_local_datasource.dart';
import '../datasources/telemetria_remote_datasource.dart';
import '../models/evento_irrigacao.dart';
import '../models/registro_telemetria.dart';

/// Resultado detalhado de uma rotina de sincronização em lote.
class SyncResult {
  final int totalPendentes;
  final int sincronizadosComSucesso;
  final int falhas;
  final String mensagem;

  const SyncResult({
    required this.totalPendentes,
    required this.sincronizadosComSucesso,
    required this.falhas,
    required this.mensagem,
  });

  bool get sucessoIntegral => falhas == 0 && totalPendentes > 0;
}

/// Repositório Offline-First do AgroSense Mesh.
///
/// Atende ao **Requisito 2** da AP2B:
/// - O banco local SQLite atua como Fonte Única da Verdade (Single Source of Truth).
/// - Escrita resiliente imediata com marcador `sincronizado: false`.
/// - Fallback transparente em quedas de rede (modo avião).
class TelemetriaRepository {
  final TelemetriaLocalDatasource _localDatasource;
  final TelemetriaRemoteDatasource _remoteDatasource;

  TelemetriaRepository({
    required TelemetriaLocalDatasource localDatasource,
    required TelemetriaRemoteDatasource remoteDatasource,
  })  : _localDatasource = localDatasource,
        _remoteDatasource = remoteDatasource;

  // ==========================================================================
  // TELEMETRIA (CRUD OFFLINE-FIRST)
  // ==========================================================================

  Future<List<RegistroTelemetria>> listarTelemetrias() async {
    try {
      final remotas = await _remoteDatasource.buscarTelemetriasRemotas();
      for (final r in remotas) {
        await _localDatasource.salvarOuAtualizarTelemetria(r);
      }
    } catch (_) {}
    return await _localDatasource.listarTodasTelemetrias();
  }

  Future<List<RegistroTelemetria>> listarTelemetriasPendentes() async {
    return await _localDatasource.listarTelemetriasPendentes();
  }

  /// Grava a leitura localmente e tenta envio assíncrono com a API REST.
  /// Aplica a regra central do AgroSense: se Umidade < 40%, dispara irrigação.
  Future<RegistroTelemetria> registrarTelemetria(RegistroTelemetria nova) async {
    // 1. Escrita resiliente no SQLite com sincronizado: false
    final pendente = nova.copyWith(sincronizado: false);
    await _localDatasource.salvarOuAtualizarTelemetria(pendente);

    // 2. Regra de Negócio: Se Umidade < 40%, aciona automaticamente a válvula de irrigação
    if (pendente.precisaIrrigacao) {
      final irrigacaoAutomatica = EventoIrrigacao(
        id: 'IRR-AUTO-${DateTime.now().millisecondsSinceEpoch}',
        telemetriaId: pendente.id,
        zona: pendente.zona,
        valvulaAcionada: true,
        volumeLitros: 120.0,
        motivo: 'Umidade do solo em ${pendente.umidadeSolo.toStringAsFixed(1)}% (< 40.0%)',
        timestamp: DateTime.now(),
        sincronizado: false,
      );
      await registrarEventoIrrigacao(irrigacaoAutomatica);
    }

    // 3. Tentativa de sincronização com API Externa
    try {
      final sucesso = await _remoteDatasource.enviarTelemetria(pendente);
      if (sucesso) {
        final confirmado = pendente.copyWith(sincronizado: true);
        await _localDatasource.salvarOuAtualizarTelemetria(confirmado);
        return confirmado;
      }
    } catch (_) {
      // Falha de rede silenciosa: o dado permanece seguro localmente no SQLite
    }

    return pendente;
  }

  Future<void> removerTelemetria(String id) async {
    await _localDatasource.removerTelemetriaPorId(id);
    try {
      await _remoteDatasource.excluirTelemetriaRemota(id);
    } catch (_) {}
  }

  // ==========================================================================
  // HISTÓRICO DE IRRIGAÇÃO
  // ==========================================================================

  Future<List<EventoIrrigacao>> listarIrrigacoes() async {
    return await _localDatasource.listarTodasIrrigacoes();
  }

  Future<List<EventoIrrigacao>> listarIrrigacoesPendentes() async {
    return await _localDatasource.listarIrrigacoesPendentes();
  }

  Future<EventoIrrigacao> registrarEventoIrrigacao(EventoIrrigacao evento) async {
    final pendente = evento.copyWith(sincronizado: false);
    await _localDatasource.salvarOuAtualizarIrrigacao(pendente);

    try {
      final sucesso = await _remoteDatasource.enviarEventoIrrigacao(pendente);
      if (sucesso) {
        final confirmado = pendente.copyWith(sincronizado: true);
        await _localDatasource.salvarOuAtualizarIrrigacao(confirmado);
        return confirmado;
      }
    } catch (_) {}

    return pendente;
  }

  Future<void> removerIrrigacao(String id) async {
    await _localDatasource.removerIrrigacaoPorId(id);
  }

  // ==========================================================================
  // SINCRONIZAÇÃO EM LOTE (OFFLINE -> CLOUD)
  // ==========================================================================

  /// Sincroniza todos os registros pendentes do SQLite com a nuvem.
  Future<SyncResult> sincronizarTudo() async {
    final telemetriasPendentes = await _localDatasource.listarTelemetriasPendentes();
    final irrigacoesPendentes = await _localDatasource.listarIrrigacoesPendentes();

    final totalPendentes = telemetriasPendentes.length + irrigacoesPendentes.length;
    if (totalPendentes == 0) {
      return const SyncResult(
        totalPendentes: 0,
        sincronizadosComSucesso: 0,
        falhas: 0,
        mensagem: 'Todos os dados de telemetria já estão sincronizados.',
      );
    }

    int sucessoCount = 0;
    int falhasCount = 0;

    // Sincroniza Telemetrias
    for (final t in telemetriasPendentes) {
      try {
        final sucesso = await _remoteDatasource.enviarTelemetria(t);
        if (sucesso) {
          await _localDatasource.salvarOuAtualizarTelemetria(t.copyWith(sincronizado: true));
          sucessoCount++;
        } else {
          falhasCount++;
        }
      } catch (_) {
        falhasCount++;
      }
    }

    // Sincroniza Irrigações
    for (final i in irrigacoesPendentes) {
      try {
        final sucesso = await _remoteDatasource.enviarEventoIrrigacao(i);
        if (sucesso) {
          await _localDatasource.salvarOuAtualizarIrrigacao(i.copyWith(sincronizado: true));
          sucessoCount++;
        } else {
          falhasCount++;
        }
      } catch (_) {
        falhasCount++;
      }
    }

    // Baixa leituras sincronizadas de outros nós/dispositivos do cluster
    try {
      final remotas = await _remoteDatasource.buscarTelemetriasRemotas();
      for (final r in remotas) {
        await _localDatasource.salvarOuAtualizarTelemetria(r);
      }
    } catch (_) {}

    return SyncResult(
      totalPendentes: totalPendentes,
      sincronizadosComSucesso: sucessoCount,
      falhas: falhasCount,
      mensagem: falhasCount == 0
          ? '$sucessoCount registro(s) sincronizado(s) com sucesso!'
          : 'Sincronizados: $sucessoCount | Falhas de rede: $falhasCount',
    );
  }
}

