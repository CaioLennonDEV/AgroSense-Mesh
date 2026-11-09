import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Helper para inicialização e controle do SQLite no AgroSense Mesh Mobile.
///
/// Atende ao **Requisito 2** da AP2B:
/// - Persistência relacional local como Fonte Única da Verdade (Single Source of Truth).
/// - Suporte a operações assíncronas (Future, async/await).
class DatabaseHelper {
  static const String _dbName = 'agrosense_mesh.db';
  static const int _dbVersion = 1;

  Database? _db;

  DatabaseHelper([Database? injectedDb]) : _db = injectedDb;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 1. Tabela de Telemetrias de Solo (Sensor, Zona, Umidade, Bateria)
    await db.execute('''
      CREATE TABLE telemetrias (
        id TEXT PRIMARY KEY,
        sensor_id TEXT NOT NULL,
        zona TEXT NOT NULL,
        umidade_solo REAL NOT NULL,
        temperatura REAL NOT NULL,
        nivel_bateria INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 2. Tabela de Eventos e Histórico de Irrigação (Disparo quando Umidade < 40%)
    await db.execute('''
      CREATE TABLE eventos_irrigacao (
        id TEXT PRIMARY KEY,
        telemetria_id TEXT,
        zona TEXT NOT NULL,
        valvula_acionada INTEGER NOT NULL DEFAULT 1,
        volume_litros REAL NOT NULL,
        motivo TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (telemetria_id) REFERENCES telemetrias (id) ON DELETE SET NULL
      )
    ''');

    // Pré-população com leituras iniciais das Zonas A, B, C, D e E
    await _popularDadosIniciais(db);
  }

  Future<void> _popularDadosIniciais(Database db) async {
    final batch = db.batch();
    final agora = DateTime.now();

    // Dados iniciais das Zonas de Plantio ativas (Zona A, Zona B, Zona C)
    final leituras = [
      {
        'id': 'TEL-INIT-01',
        'sensor_id': 'sensor-A-01',
        'zona': 'Zona A',
        'umidade_solo': 48.5,
        'temperatura': 26.2,
        'nivel_bateria': 95,
        'timestamp': agora.subtract(const Duration(minutes: 45)).toIso8601String(),
        'sincronizado': 1,
      },
      {
        'id': 'TEL-INIT-02',
        'sensor_id': 'sensor-B-01',
        'zona': 'Zona B',
        'umidade_solo': 34.0, // < 40% (Dispara irrigação!)
        'temperatura': 29.8,
        'nivel_bateria': 88,
        'timestamp': agora.subtract(const Duration(minutes: 30)).toIso8601String(),
        'sincronizado': 1,
      },
      {
        'id': 'TEL-INIT-03',
        'sensor_id': 'sensor-C-01',
        'zona': 'Zona C',
        'umidade_solo': 52.0,
        'temperatura': 24.5,
        'nivel_bateria': 92,
        'timestamp': agora.subtract(const Duration(minutes: 20)).toIso8601String(),
        'sincronizado': 1,
      },
    ];

    for (final l in leituras) {
      batch.insert('telemetrias', l);
    }

    // Histórico de Irrigação disparado para a Zona B
    batch.insert('eventos_irrigacao', {
      'id': 'IRR-INIT-01',
      'telemetria_id': 'TEL-INIT-02',
      'zona': 'Zona B',
      'valvula_acionada': 1,
      'volume_litros': 150.0,
      'motivo': 'Umidade abaixo de 40.0% (Lida: 34.0%)',
      'timestamp': agora.subtract(const Duration(minutes: 29)).toIso8601String(),
      'sincronizado': 1,
    });

    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

