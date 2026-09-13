import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AgrovidaDatabase {
  AgrovidaDatabase._();

  static final AgrovidaDatabase instance = AgrovidaDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final databasePath = join(await getDatabasesPath(), 'agrovida.db');
    final database = await openDatabase(
      databasePath,
      version: 6,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTerrenosTable(db);
        await _createObservacionesTable(db);
        await _createActividadesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createObservacionesTable(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE terrenos ADD COLUMN limite_json TEXT NOT NULL DEFAULT \'[]\'',
          );
        }
        if (oldVersion < 4) {
          await _createActividadesTable(db);
        }
        if (oldVersion < 5) {
          await db.execute(
            "ALTER TABLE terrenos ADD COLUMN finca_nombre TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE terrenos ADD COLUMN finca_descripcion TEXT NOT NULL DEFAULT ''",
          );
          await db.execute(
            "ALTER TABLE terrenos ADD COLUMN descripcion TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            "ALTER TABLE terrenos ADD COLUMN parcela_public_id TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
    _database = database;
    return database;
  }

  Future<void> _createTerrenosTable(Database db) async {
    await db.execute('''
      CREATE TABLE terrenos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        parcela_public_id TEXT NOT NULL DEFAULT '',
        nombre TEXT NOT NULL,
        propietario TEXT NOT NULL,
        finca_nombre TEXT NOT NULL DEFAULT '',
        finca_descripcion TEXT NOT NULL DEFAULT '',
        descripcion TEXT NOT NULL DEFAULT '',
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        creado_en TEXT NOT NULL,
        limite_json TEXT NOT NULL DEFAULT '[]'
      )
    ''');
  }

  Future<void> _createObservacionesTable(Database db) async {
    await db.execute('''
      CREATE TABLE observaciones(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        terreno_id INTEGER NOT NULL,
        texto TEXT NOT NULL,
        creado_en TEXT NOT NULL,
        FOREIGN KEY (terreno_id) REFERENCES terrenos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_observaciones_terreno
      ON observaciones(terreno_id)
    ''');
  }

  Future<void> _createActividadesTable(Database db) async {
    await db.execute('''
      CREATE TABLE actividades(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        terreno_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        estado TEXT NOT NULL,
        fecha TEXT NOT NULL,
        evidencia_ruta TEXT,
        creado_en TEXT NOT NULL,
        FOREIGN KEY (terreno_id) REFERENCES terrenos(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_actividades_terreno
      ON actividades(terreno_id)
    ''');
  }
}
