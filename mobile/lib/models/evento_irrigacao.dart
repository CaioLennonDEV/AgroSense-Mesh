import 'dart:convert';

/// Entidade de domínio relacionada que modela o histórico de acionamentos de irrigação.
///
/// Atende ao **Requisito 2** da AP2B:
/// - Entidade secundária relacionada (1-N com telemetria).
/// - Suporte a persistência local com chave estrangeira.
class EventoIrrigacao {
  final String id;
  final String? telemetriaId;
  final String zona;
  final bool valvulaAcionada;
  final double volumeLitros;
  final String motivo;
  final DateTime timestamp;
  final bool sincronizado;

  const EventoIrrigacao({
    required this.id,
    this.telemetriaId,
    required this.zona,
    required this.valvulaAcionada,
    required this.volumeLitros,
    required this.motivo,
    required this.timestamp,
    this.sincronizado = false,
  });

  EventoIrrigacao copyWith({
    String? id,
    String? telemetriaId,
    String? zona,
    bool? valvulaAcionada,
    double? volumeLitros,
    String? motivo,
    DateTime? timestamp,
    bool? sincronizado,
  }) {
    return EventoIrrigacao(
      id: id ?? this.id,
      telemetriaId: telemetriaId ?? this.telemetriaId,
      zona: zona ?? this.zona,
      valvulaAcionada: valvulaAcionada ?? this.valvulaAcionada,
      volumeLitros: volumeLitros ?? this.volumeLitros,
      motivo: motivo ?? this.motivo,
      timestamp: timestamp ?? this.timestamp,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'telemetria_id': telemetriaId,
        'zona': zona,
        'valvula_acionada': valvulaAcionada ? 1 : 0,
        'volume_litros': volumeLitros,
        'motivo': motivo,
        'timestamp': timestamp.toIso8601String(),
        'sincronizado': sincronizado ? 1 : 0,
      };

  factory EventoIrrigacao.fromMap(Map<String, dynamic> map) {
    final syncValue = map['sincronizado'];
    final bool isSync = syncValue == 1 || syncValue == true || syncValue == '1' || syncValue == 'true';

    final valvulaVal = map['valvula_acionada'] ?? map['valvulaAcionada'];
    final bool isValvula = valvulaVal == 1 || valvulaVal == true || valvulaVal == '1' || valvulaVal == 'true';

    final dataIso = (map['timestamp'] ?? map['data_acionamento']) as String?;
    final data = dataIso != null ? DateTime.parse(dataIso) : DateTime.now();

    return EventoIrrigacao(
      id: map['id']?.toString() ?? 'IRR-${DateTime.now().millisecondsSinceEpoch}',
      telemetriaId: map['telemetria_id']?.toString() ?? map['telemetriaId']?.toString(),
      zona: (map['zona'] ?? 'Zona A').toString(),
      valvulaAcionada: isValvula,
      volumeLitros: (map['volume_litros'] ?? map['volumeLitros'] as num?)?.toDouble() ?? 50.0,
      motivo: (map['motivo'] ?? 'Acionamento Automático por Umidade Baixa').toString(),
      timestamp: data,
      sincronizado: isSync,
    );
  }

  String toJson() => jsonEncode(toMap());

  @override
  String toString() {
    final statusValvula = valvulaAcionada ? 'ABERTA' : 'FECHADA';
    final syncIcon = sincronizado ? '✓ SYNC' : '⏳ PENDENTE';
    return 'Irrigação [ID: $id | $zona | Válvula: $statusValvula | ${volumeLitros.toStringAsFixed(1)}L | $motivo | $syncIcon]';
  }
}

