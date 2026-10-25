import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // Versi dinaikkan ke 3 untuk memicu onUpgrade jika tabel di HP masih versi sebelumnya
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // Membuat tabel notes pertama kali
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT,
        category TEXT,
        color INTEGER,
        is_pinned INTEGER DEFAULT 0
      )
    ''');
  }

  // Tugas 3: Migrasi database dinamis & aman memeriksa PRAGMA table_info
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    final columnsResult = await db.rawQuery('PRAGMA table_info(notes)');
    final existingColumns = columnsResult.map((c) => c['name'] as String).toSet();

    if (!existingColumns.contains('created_at')) {
      await db.execute('ALTER TABLE notes ADD COLUMN created_at TEXT');
    }
    if (!existingColumns.contains('category')) {
      await db.execute('ALTER TABLE notes ADD COLUMN category TEXT');
    }
    if (!existingColumns.contains('color')) {
      await db.execute('ALTER TABLE notes ADD COLUMN color INTEGER');
    }
    if (!existingColumns.contains('is_pinned')) {
      await db.execute('ALTER TABLE notes ADD COLUMN is_pinned INTEGER DEFAULT 0');
    }
  }

  // CREATE: Menyimpan catatan baru
  Future<int> insert(Note note) async {
    final db = await instance.database;
    return await db.insert('notes', note.toMap());
  }

  // READ: Mengambil semua catatan, diurutkan dari yang disematkan (pin) lalu id terbaru
  Future<List<Note>> getAllNotes({String? category}) async {
    final db = await instance.database;
    List<Map<String, dynamic>> result;

    if (category != null && category != 'Semua') {
      result = await db.query(
        'notes',
        where: 'category = ?',
        whereArgs: [category],
        orderBy: 'is_pinned DESC, id DESC',
      );
    } else {
      result = await db.query(
        'notes',
        orderBy: 'is_pinned DESC, id DESC',
      );
    }

    return result.map((e) => Note.fromMap(e)).toList();
  }

  // Tugas 2: Pencarian catatan menggunakan SQL LIKE pada judul dan isi
  Future<List<Note>> searchNotes(String keyword, {String? category}) async {
    final db = await instance.database;
    final term = '%$keyword%';
    List<Map<String, dynamic>> result;

    if (category != null && category != 'Semua') {
      result = await db.query(
        'notes',
        where: '(title LIKE ? OR content LIKE ?) AND category = ?',
        whereArgs: [term, term, category],
        orderBy: 'is_pinned DESC, id DESC',
      );
    } else {
      result = await db.query(
        'notes',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: [term, term],
        orderBy: 'is_pinned DESC, id DESC',
      );
    }

    return result.map((e) => Note.fromMap(e)).toList();
  }

  // UPDATE: Memperbarui catatan
  Future<int> update(Note note) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  // Fitur Tambahan Pro: Toggle Pin catatan
  Future<int> togglePin(int id, bool isPinned) async {
    final db = await instance.database;
    return await db.update(
      'notes',
      {'is_pinned': isPinned ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // DELETE: Menghapus catatan berdasarkan ID
  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // Tutup database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
