import 'dart:convert';

/// Modelo de domínio que representa uma leitura de sensor no campo.
///
/// Atende ao **Requisito 2** da AP2B:
/// - Persistência relacional via SQLite (`sqflite`).
/// - Serialização bidirecional Map/JSON compatível com API REST.
/// - Marcador de sincronização para arquitetura Offline-First.
class RegistroTelemetria {
  final String id;
  final String sensorId;
  final String zona;
  final double umidadeSolo; // Percentual (%) de 0.0 a 100.0
  final double temperatura; // Graus Celsius (°C)
  final int nivelBateria; // Percentual (%) de 0 a 100
  final DateTime timestamp;
  final bool sincronizado;

  const RegistroTelemetria({
    required this.id,
    required this.sensorId,
    required this.zona,
    required this.umidadeSolo,
    required this.temperatura,
    required this.nivelBateria,
    required this.timestamp,
    this.sincronizado = false,
  });

  /// Regra de Negócio Central do AgroSense Mesh:
  /// Se Umidade < 40%, o sistema aciona automaticamente a válvula de irrigação.
  bool get precisaIrrigacao => umidadeSolo < 40.0;

  /// Cria uma cópia com alteração de atributos ou status de sincronização.
  RegistroTelemetria copyWith({
    String? id,
    String? sensorId,
    String? zona,
    double? umidadeSolo,
    double? temperatura,
    int? nivelBateria,
    DateTime? timestamp,
    bool? sincronizado,
  }) {
    return RegistroTelemetria(
      id: id ?? this.id,
      sensorId: sensorId ?? this.sensorId,
      zona: zona ?? this.zona,
      umidadeSolo: umidadeSolo ?? this.umidadeSolo,
      temperatura: temperatura ?? this.temperatura,
      nivelBateria: nivelBateria ?? this.nivelBateria,
      timestamp: timestamp ?? this.timestamp,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// Converte para Map compatível com SQLite (booleano convertido para 0 ou 1).
  Map<String, dynamic> toMap() => {
        'id': id,
        'sensor_id': sensorId,
        'zona': zona,
        'umidade_solo': umidadeSolo,
        'temperatura': temperatura,
        'nivel_bateria': nivelBateria,
        'timestamp': timestamp.toIso8601String(),
        'sincronizado': sincronizado ? 1 : 0,
      };

  /// Construtor Factory a partir de registro do SQLite ou payload JSON da API REST.
  factory RegistroTelemetria.fromMap(Map<String, dynamic> map) {
    final bateria = (map['nivel_bateria'] ?? map['nivelBateria'] as num?)?.toInt() ?? 100;
    if (bateria < 0 || bateria > 100) {
      throw ArgumentError('Nível de bateria inválido (deve ser entre 0 e 100): $bateria');
    }

    final umidade = (map['umidade_solo'] ?? map['moisture'] ?? map['umidade'] as num?)?.toDouble() ?? 50.0;
    if (umidade < 0.0 || umidade > 100.0) {
      throw ArgumentError('Umidade do solo inválida (deve ser entre 0 e 100): $umidade');
    }

    final dataIso = (map['timestamp'] ?? map['data_hora']) as String?;
    final data = dataIso != null ? DateTime.parse(dataIso) : DateTime.now();

    final syncValue = map['sincronizado'];
    final bool isSync = syncValue == 1 || syncValue == true || syncValue == '1' || syncValue == 'true';

    return RegistroTelemetria(
      id: map['id']?.toString() ?? 'TEL-${DateTime.now().millisecondsSinceEpoch}',
      sensorId: (map['sensor_id'] ?? map['sensorId'] ?? 'SENSOR-DESCONHECIDO').toString(),
      zona: (map['zona'] ?? map['zone'] ?? 'Zona A').toString(),
      umidadeSolo: umidade,
      temperatura: (map['temperatura'] ?? map['temperature'] as num?)?.toDouble() ?? 25.0,
      nivelBateria: bateria,
      timestamp: data,
      sincronizado: isSync,
    );
  }

  String toJson() => jsonEncode(toMap());

  @override
  String toString() {
    final syncIcon = sincronizado ? '✓ SYNC' : '⏳ PENDENTE';
    return 'Telemetria [ID: $id | Sensor: $sensorId | $zona | Umidade: ${umidadeSolo.toStringAsFixed(1)}% | Temp: ${temperatura.toStringAsFixed(1)}°C | Bat: $nivelBateria% | $syncIcon]';
  }
}

