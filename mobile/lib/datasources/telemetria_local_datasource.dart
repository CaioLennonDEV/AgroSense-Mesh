import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/evento_irrigacao.dart';
import '../models/registro_telemetria.dart';
import 'database_helper.dart';

/// Contrato para persistência local SQLite do AgroSense Mesh.
///
/// Atende ao **Requisito 2** da AP2B:
/// - Inversão de dependência (desacoplamento para testes limpos).
/// - As 4 operações fundamentais de CRUD (insert, query, update, delete).
abstract class TelemetriaLocalDatasource {
  // Telemetrias
  Future<void> salvarOuAtualizarTelemetria(RegistroTelemetria telemetria);
  Future<List<RegistroTelemetria>> listarTodasTelemetrias();
  Future<List<RegistroTelemetria>> listarTelemetriasPendentes();
  Future<RegistroTelemetria?> buscarTelemetriaPorId(String id);
  Future<void> removerTelemetriaPorId(String id);

  // Irrigação
  Future<void> salvarOuAtualizarIrrigacao(EventoIrrigacao evento);
  Future<List<EventoIrrigacao>> listarTodasIrrigacoes();
  Future<List<EventoIrrigacao>> listarIrrigacoesPendentes();
  Future<void> removerIrrigacaoPorId(String id);
}

/// Implementação oficial do DataSource local com `sqflite` (e suporte em memória no Web).
class TelemetriaLocalDatasourceImpl implements TelemetriaLocalDatasource {
  final DatabaseHelper _dbHelper;

  // Armazenamento em memória sincronizado com SharedPreferences para Flutter Web
  static final Map<String, RegistroTelemetria> _webTelemetrias = {};
  static final Map<String, EventoIrrigacao> _webIrrigacoes = {};
  static bool _webInicializado = false;

  static const _kStorageTelemetrias = 'agrosense_telemetrias_cache_v3';
  static const _kStorageIrrigacoes = 'agrosense_irrigacoes_cache_v3';

  TelemetriaLocalDatasourceImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper() {
    if (kIsWeb && !_webInicializado) {
      _popularWebMock();
      _carregarWebStorage();
      _webInicializado = true;
    }
  }

  static Future<void> _salvarWebStorage() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final listTel = _webTelemetrias.values.map((t) => t.toMap()).toList();
      await prefs.setString(_kStorageTelemetrias, jsonEncode(listTel));

      final listIrr = _webIrrigacoes.values.map((i) => i.toMap()).toList();
      await prefs.setString(_kStorageIrrigacoes, jsonEncode(listIrr));
    } catch (_) {}
  }

  static Future<void> _carregarWebStorage() async {
    if (!kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final strTel = prefs.getString(_kStorageTelemetrias);
      if (strTel != null && strTel.isNotEmpty) {
        final decoded = jsonDecode(strTel);
        if (decoded is List && decoded.isNotEmpty) {
          _webTelemetrias.clear();
          for (final item in decoded) {
            final t = RegistroTelemetria.fromMap(Map<String, dynamic>.from(item as Map));
            _webTelemetrias[t.id] = t;
          }
        }
      }

      final strIrr = prefs.getString(_kStorageIrrigacoes);
      if (strIrr != null && strIrr.isNotEmpty) {
        final decoded = jsonDecode(strIrr);
        if (decoded is List && decoded.isNotEmpty) {
          _webIrrigacoes.clear();
          for (final item in decoded) {
            final i = EventoIrrigacao.fromMap(Map<String, dynamic>.from(item as Map));
            _webIrrigacoes[i.id] = i;
          }
        }
      }
    } catch (_) {}
  }

  void _popularWebMock() {
    final agora = DateTime.now();
    final leituras = [
      RegistroTelemetria(
        id: 'TEL-INIT-01',
        sensorId: 'SENSOR-A1',
        zona: 'Zona A',
        umidadeSolo: 48.5,
        temperatura: 26.2,
        nivelBateria: 95,
        timestamp: agora.subtract(const Duration(minutes: 45)),
        sincronizado: true,
      ),
      RegistroTelemetria(
        id: 'TEL-INIT-02',
        sensorId: 'SENSOR-B2',
        zona: 'Zona B',
        umidadeSolo: 34.0, // < 40% (crítica)
        temperatura: 29.8,
        nivelBateria: 88,
        timestamp: agora.subtract(const Duration(minutes: 30)),
        sincronizado: true,
      ),
      RegistroTelemetria(
        id: 'TEL-INIT-03',
        sensorId: 'sensor-C-01',
        zona: 'Zona C',
        umidadeSolo: 52.0,
        temperatura: 24.5,
        nivelBateria: 92,
        timestamp: agora.subtract(const Duration(minutes: 20)),
        sincronizado: true,
      ),
      RegistroTelemetria(
        id: 'TEL-INIT-04',
        sensorId: 'sensor-D-01',
        zona: 'Zona D',
        umidadeSolo: 38.2, // < 40% (crítica)
        temperatura: 31.0,
        nivelBateria: 85,
        timestamp: agora.subtract(const Duration(minutes: 15)),
        sincronizado: true,
      ),
      RegistroTelemetria(
        id: 'TEL-INIT-05',
        sensorId: 'sensor-E-01',
        zona: 'Zona E',
        umidadeSolo: 64.7,
        temperatura: 23.8,
        nivelBateria: 97,
        timestamp: agora.subtract(const Duration(minutes: 10)),
        sincronizado: true,
      ),
    ];

    for (final l in leituras) {
      _webTelemetrias[l.id] = l;
    }

    _webIrrigacoes['IRR-INIT-01'] = EventoIrrigacao(
      id: 'IRR-INIT-01',
      telemetriaId: 'TEL-INIT-02',
      zona: 'Zona B',
      valvulaAcionada: true,
      volumeLitros: 150.0,
      motivo: 'Umidade abaixo de 40.0% (Lida: 34.0%)',
      timestamp: agora.subtract(const Duration(minutes: 29)),
      sincronizado: true,
    );

    _webIrrigacoes['IRR-INIT-02'] = EventoIrrigacao(
      id: 'IRR-INIT-02',
      telemetriaId: 'TEL-INIT-04',
      zona: 'Zona D',
      valvulaAcionada: true,
      volumeLitros: 200.0,
      motivo: 'Umidade abaixo de 40.0% (Lida: 38.2%)',
      timestamp: agora.subtract(const Duration(minutes: 14)),
      sincronizado: true,
    );
  }

  Future<Database> get _db async => await _dbHelper.database;

  @override
  Future<void> salvarOuAtualizarTelemetria(RegistroTelemetria telemetria) async {
    if (kIsWeb) {
      _webTelemetrias[telemetria.id] = telemetria;
      _salvarWebStorage();
      return;
    }
    final db = await _db;
    await db.insert(
      'telemetrias',
      telemetria.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<RegistroTelemetria>> listarTodasTelemetrias() async {
    if (kIsWeb) {
      final list = _webTelemetrias.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'telemetrias',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => RegistroTelemetria.fromMap(map)).toList();
  }

  @override
  Future<List<RegistroTelemetria>> listarTelemetriasPendentes() async {
    if (kIsWeb) {
      return _webTelemetrias.values.where((t) => !t.sincronizado).toList();
    }
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'telemetrias',
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => RegistroTelemetria.fromMap(map)).toList();
  }

  @override
  Future<RegistroTelemetria?> buscarTelemetriaPorId(String id) async {
    if (kIsWeb) {
      return _webTelemetrias[id];
    }
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'telemetrias',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RegistroTelemetria.fromMap(maps.first);
  }

  @override
  Future<void> removerTelemetriaPorId(String id) async {
    if (kIsWeb) {
      _webTelemetrias.remove(id);
      _salvarWebStorage();
      return;
    }
    final db = await _db;
    await db.delete(
      'telemetrias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> salvarOuAtualizarIrrigacao(EventoIrrigacao evento) async {
    if (kIsWeb) {
      _webIrrigacoes[evento.id] = evento;
      _salvarWebStorage();
      return;
    }
    final db = await _db;
    await db.insert(
      'eventos_irrigacao',
      evento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<EventoIrrigacao>> listarTodasIrrigacoes() async {
    if (kIsWeb) {
      final list = _webIrrigacoes.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'eventos_irrigacao',
      orderBy: 'timestamp DESC',
    );
    return maps.map((map) => EventoIrrigacao.fromMap(map)).toList();
  }

  @override
  Future<List<EventoIrrigacao>> listarIrrigacoesPendentes() async {
    if (kIsWeb) {
      return _webIrrigacoes.values.where((i) => !i.sincronizado).toList();
    }
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      'eventos_irrigacao',
      where: 'sincronizado = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
    return maps.map((map) => EventoIrrigacao.fromMap(map)).toList();
  }

  @override
  Future<void> removerIrrigacaoPorId(String id) async {
    if (kIsWeb) {
      _webIrrigacoes.remove(id);
      _salvarWebStorage();
      return;
    }
    final db = await _db;
    await db.delete(
      'eventos_irrigacao',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
