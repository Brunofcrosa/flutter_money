// flutter_money/lib/servicos/banco_dados.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_money/modelos/receita.dart';
import 'package:flutter_money/modelos/despesa.dart';
import 'package:flutter_money/modelos/comprovante.dart';
import 'package:flutter_money/modelos/usuario.dart';

class BancoDados {
  static final BancoDados instancia = BancoDados._init();
  static Database? _database;

  BancoDados._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('flutter_money.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 5,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE receitas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        descricao TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE despesas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT,
        valor REAL NOT NULL,
        numParcelas INTEGER,
        dataVencimento TEXT NOT NULL,
        descricao TEXT, -- <<< AQUI: COLUNA DESCRICAO ADICIONADA NA CRIACAO
        tipo TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE comprovantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        caminhoArquivo TEXT NOT NULL,
        dataCaptura TEXT NOT NULL,
        idDespesaVinculada INTEGER,
        descricao TEXT,
        FOREIGN KEY (idDespesaVinculada) REFERENCES despesas (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        senha TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE comprovantes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          caminhoArquivo TEXT NOT NULL,
          dataCaptura TEXT NOT NULL,
          idDespesaVinculada INTEGER,
          descricao TEXT,
          FOREIGN KEY (idDespesaVinculada) REFERENCES despesas (id) ON DELETE SET NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE usuarios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          email TEXT NOT NULL UNIQUE,
          senha TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      var tableInfo = await db.rawQuery('PRAGMA table_info(despesas)');
      var hasDescricaoColumn = tableInfo.any(
        (column) => column['name'] == 'descricao',
      );
      if (!hasDescricaoColumn) {
        await db.execute('ALTER TABLE despesas ADD COLUMN descricao TEXT;');
      }
    }
  }

  Future<int> inserirUsuario(Usuario usuario) async {
    final db = await instancia.database;
    return await db.insert(
      'usuarios',
      usuario.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Usuario?> buscarUsuarioPorEmail(String email) async {
    final db = await instancia.database;
    final maps = await db.query(
      'usuarios',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Usuario.fromMap(maps.first);
    }
    return null;
  }

  Future<int> atualizarUsuario(Usuario usuario) async {
    final db = await instancia.database;
    return db.update(
      'usuarios',
      usuario.toMap(),
      where: 'id = ?',
      whereArgs: [usuario.id],
    );
  }

  Future<int> removerUsuario(int id) async {
    final db = await instancia.database;
    return await db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> inserirReceita(Receita receita) async {
    final db = await instancia.database;
    return await db.insert(
      'receitas',
      receita.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Receita>> listarReceitas() async {
    final db = await instancia.database;
    final maps = await db.query('receitas', orderBy: 'data DESC');
    return List.generate(maps.length, (i) => Receita.fromMap(maps[i]));
  }

  Future<int> atualizarReceita(Receita receita) async {
    final db = await instancia.database;
    return db.update(
      'receitas',
      receita.toMap(),
      where: 'id = ?',
      whereArgs: [receita.id],
    );
  }

  Future<int> removerReceita(int id) async {
    final db = await instancia.database;
    return await db.delete('receitas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> inserirDespesa(Despesa despesa) async {
    final db = await instancia.database;
    return await db.insert(
      'despesas',
      despesa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Despesa>> listarDespesas() async {
    final db = await instancia.database;
    final maps = await db.query('despesas', orderBy: 'dataVencimento DESC');
    return List.generate(maps.length, (i) => Despesa.fromMap(maps[i]));
  }

  Future<int> atualizarDespesa(Despesa despesa) async {
    final db = await instancia.database;
    return db.update(
      'despesas',
      despesa.toMap(),
      where: 'id = ?',
      whereArgs: [despesa.id],
    );
  }

  Future<int> removerDespesa(int id) async {
    final db = await instancia.database;
    return await db.delete('despesas', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> inserirComprovante(Comprovante comprovante) async {
    final db = await instancia.database;
    return await db.insert(
      'comprovantes',
      comprovante.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Comprovante>> listarComprovantes() async {
    final db = await instancia.database;
    final maps = await db.query('comprovantes', orderBy: 'dataCaptura DESC');
    return List.generate(maps.length, (i) => Comprovante.fromMap(maps[i]));
  }

  Future<int> atualizarComprovante(Comprovante comprovante) async {
    final db = await instancia.database;
    return db.update(
      'comprovantes',
      comprovante.toMap(),
      where: 'id = ?',
      whereArgs: [comprovante.id],
    );
  }

  Future<int> removerComprovante(int id) async {
    final db = await instancia.database;
    return await db.delete('comprovantes', where: 'id = ?', whereArgs: [id]);
  }

  Future<Despesa?> buscarDespesaPorId(int id) async {
    final db = await instancia.database;
    final maps = await db.query(
      'despesas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Despesa.fromMap(maps.first) : null;
  }

  Future<List<Comprovante>> listarComprovantesPorDespesa(int idDespesa) async {
    final db = await instancia.database;
    final maps = await db.query(
      'comprovantes',
      where: 'idDespesaVinculada = ?',
      whereArgs: [idDespesa],
      orderBy: 'dataCaptura DESC',
    );
    return List.generate(maps.length, (i) => Comprovante.fromMap(maps[i]));
  }

  Future close() async {
    final db = await instancia.database;
    db.close();
  }
}
