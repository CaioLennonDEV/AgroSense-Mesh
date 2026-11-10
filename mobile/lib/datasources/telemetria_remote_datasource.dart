import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/evento_irrigacao.dart';
import '../models/registro_telemetria.dart';

/// Contrato para comunicação assíncrona com API REST externa.
///
/// Atende ao **Requisito 2** da AP2B:
/// - Comunicação HTTP assíncrona (Future, async/await).
/// - Serialização JSON (dart:convert).
/// - Verificação de status code HTTP e timeout configurado.
abstract class TelemetriaRemoteDatasource {
  Future<bool> enviarTelemetria(RegistroTelemetria telemetria);
  Future<bool> enviarEventoIrrigacao(EventoIrrigacao evento);
  Future<List<RegistroTelemetria>> buscarTelemetriasRemotas();
  Future<List<EventoIrrigacao>> buscarIrrigacoesRemotas();
  Future<bool> excluirTelemetriaRemota(String id);
}

/// Implementação padrão com `package:http`.
class TelemetriaRemoteDatasourceImpl implements TelemetriaRemoteDatasource {
  final http.Client _client;
  final Uri _telemetriaUri;
  final Uri _irrigacaoUri;
  final Duration _timeout;

  TelemetriaRemoteDatasourceImpl({
    http.Client? client,
    Uri? telemetriaUri,
    Uri? irrigacaoUri,
    Duration timeout = const Duration(seconds: 5),
  })  : _client = client ?? http.Client(),
        _telemetriaUri = telemetriaUri ?? _obterDefaultTelemetriaUri(),
        _irrigacaoUri = irrigacaoUri ?? _obterDefaultIrrigacaoUri(),
        _timeout = timeout;

  static Uri _obterDefaultTelemetriaUri() {
    if (kIsWeb) {
      // No browser (Flutter Web), utiliza a origem atual (funciona no localhost e via túnel HTTPS)
      return Uri.base.resolve('/api/telemetry');
    }
    return Uri.parse('http://localhost:3000/api/telemetry');
  }

  static Uri _obterDefaultIrrigacaoUri() {
    if (kIsWeb) {
      return Uri.base.resolve('/api/irrigation-logs');
    }
    return Uri.parse('http://localhost:3000/api/irrigation-logs');
  }

  @override
  Future<bool> enviarTelemetria(RegistroTelemetria telemetria) async {
    try {
      final response = await _client
          .post(
            _telemetriaUri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: telemetria.toJson(),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      // Captura falhas de timeout, socket ou modo avião
      return false;
    }
  }

  @override
  Future<bool> enviarEventoIrrigacao(EventoIrrigacao evento) async {
    try {
      final response = await _client
          .post(
            _irrigacaoUri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: evento.toJson(),
          )
          .timeout(_timeout);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<RegistroTelemetria>> buscarTelemetriasRemotas() async {
    try {
      final response = await _client
          .get(
            _telemetriaUri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return RegistroTelemetria(
              id: map['id']?.toString() ?? 'REMOTO-${DateTime.now().millisecondsSinceEpoch}',
              sensorId: map['sensor_id']?.toString() ?? map['sensorId']?.toString() ?? 'sensor-A-01',
              zona: map['zone']?.toString() ?? map['zona']?.toString() ?? 'Zona A',
              umidadeSolo: (map['moisture'] ?? map['umidadeSolo'] ?? map['umidade_solo'] as num?)?.toDouble() ?? 50.0,
              temperatura: (map['temperature'] ?? map['temperatura'] as num?)?.toDouble() ?? 25.0,
              nivelBateria: (map['battery'] ?? map['nivelBateria'] ?? map['nivel_bateria'] as num?)?.toInt() ?? 100,
              timestamp: map['timestamp'] != null
                  ? (DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now())
                  : DateTime.now(),
              sincronizado: true,
            );
          }).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<EventoIrrigacao>> buscarIrrigacoesRemotas() async {
    try {
      final response = await _client
          .get(
            _irrigacaoUri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            final rawZone = map['zone']?.toString() ?? 'A';
            final zone = rawZone.startsWith('Zona ') ? rawZone : 'Zona $rawZone';
            return EventoIrrigacao(
              id: map['message_id']?.toString() ?? map['id']?.toString() ?? 'IRR-${DateTime.now().millisecondsSinceEpoch}',
              telemetriaId: null,
              zona: zone,
              valvulaAcionada: true,
              volumeLitros: 150.0,
              motivo: 'Umidade crítica (${map['moisture'] ?? 35}%) consolidada pelo Líder',
              timestamp: map['activated_at'] != null
                  ? (DateTime.tryParse(map['activated_at'].toString()) ?? DateTime.now())
                  : DateTime.now(),
              sincronizado: true,
            );
          }).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<bool> excluirTelemetriaRemota(String id) async {
    try {
      final url = Uri.parse('$_telemetriaUri/$id');
      final response = await _client.delete(url).timeout(_timeout);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}

