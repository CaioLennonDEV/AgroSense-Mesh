import '../datasources/database_helper.dart';
import '../datasources/telemetria_local_datasource.dart';
import '../datasources/telemetria_remote_datasource.dart';
import '../repositories/telemetria_repository.dart';

/// Service Locator desacoplado para injeção de dependência na UI.
class AppServiceLocator {
  static AppServiceLocator? _instance;
  final TelemetriaRepository repository;

  AppServiceLocator._(this.repository);

  static AppServiceLocator get instance {
    _instance ??= AppServiceLocator._(
      TelemetriaRepository(
        localDatasource: TelemetriaLocalDatasourceImpl(
          dbHelper: DatabaseHelper(),
        ),
        remoteDatasource: TelemetriaRemoteDatasourceImpl(),
      ),
    );
    return _instance!;
  }

  /// Injeção de repositório para testes de widget ou mocks
  static void setupForTest(TelemetriaRepository testRepo) {
    _instance = AppServiceLocator._(testRepo);
  }
}

