import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';
import 'note_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final db = DatabaseHelper.instance;
  List<Note> notes = [];
  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = ['Semua', 'Kuliah', 'Tugas', 'Ide', 'Pribadi', 'Lainnya'];
  String selectedCategory = 'Semua';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Memuat data catatan dari SQLite (dengan filter kategori dan pencarian)
  Future<void> _loadNotes() async {
    try {
      final query = _searchController.text.trim();
      List<Note> data;

      if (query.isNotEmpty) {
        data = await db.searchNotes(
          query,
          category: selectedCategory == 'Semua' ? null : selectedCategory,
        );
      } else {
        data = await db.getAllNotes(
          category: selectedCategory == 'Semua' ? null : selectedCategory,
        );
      }

      if (mounted) {
        setState(() {
          notes = data;
        });
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Tugas 2: Filter Pencarian Realtime dengan SQLite LIKE
  void _onSearchChanged(String value) {
    _loadNotes();
  }

  void _openForm({Note? note}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteForm(note: note)),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  // Toggle status Pin catatan
  Future<void> _togglePin(Note note) async {
    final newStatus = !note.isPinned;
    await db.togglePin(note.id!, newStatus);
    _loadNotes();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? 'Catatan disematkan ke atas 📌' : 'Sematan dilepas',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Tugas 1: Konfirmasi Hapus dengan AlertDialog Elegan
  void _confirmDelete(Note note) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 26),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hapus Catatan?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Apakah Anda yakin ingin menghapus catatan ini?',
                style: TextStyle(color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  note.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await db.delete(note.id!);
                _loadNotes();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Catatan "${note.title}" berhasil dihapus'),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      action: SnackBarAction(
                        label: 'URUNGKAN',
                        textColor: Colors.amberAccent,
                        onPressed: () async {
                          await db.insert(note);
                          _loadNotes();
                        },
                      ),
                    ),
                  );
                }
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  // Tugas 3: Format tanggal ramah pengguna (misal: 25 Okt 2026 • 11:30)
  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString);
      final day = dt.day.toString().padLeft(2, '0');
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      final month = months[dt.month - 1];
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$day $month $year • $hour:$minute';
    } catch (_) {
      return isoString;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'Kuliah':
        return Icons.school_outlined;
      case 'Tugas':
        return Icons.assignment_outlined;
      case 'Ide':
        return Icons.lightbulb_outline;
      case 'Pribadi':
        return Icons.lock_outline;
      default:
        return Icons.bookmark_border;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sticky_note_2_rounded, size: 26),
            SizedBox(width: 8),
            Text(
              'CatatanKu',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${notes.length} Catatan',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: Colors.indigo.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Catatan Baru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Header Bar: Pencarian Realtime (Tugas 2)
          Container(
            color: Colors.indigo.shade800,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari judul atau isi catatan...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadNotes();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Bar Kategori / Filter Chips (Nilai Tambahan)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 13,
                      ),
                      selected: isSelected,
                      selectedColor: Colors.indigo.shade700,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => selectedCategory = cat);
                          _loadNotes();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Area Daftar Catatan
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : notes.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchController.text.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.note_add_outlined,
                                size: 80,
                                color: Colors.indigo.shade200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'Tidak ada catatan yang cocok'
                                    : 'Belum Ada Catatan ✨',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchController.text.isNotEmpty
                                    ? 'Coba gunakan kata kunci pencarian yang lain.'
                                    : 'Mulai buat catatan pertamamu untuk tugas,\nkuliah, atau ide cemerlang.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                        physics: const BouncingScrollPhysics(),
                        itemCount: notes.length,
                        itemBuilder: (context, i) {
                          final note = notes[i];
                          final cardBg = note.color != null
                              ? Color(note.color!)
                              : Colors.white;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: note.isPinned
                                    ? Colors.amber.shade600
                                    : Colors.black.withAlpha(20),
                                width: note.isPinned ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(12),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openForm(note: note),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Baris Atas: Kategori Badge, Tombol Pin, dan Tombol Hapus
                                      Row(
                                        children: [
                                          // Badge Kategori (Nilai Tambahan)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withAlpha(20),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getCategoryIcon(note.category),
                                                  size: 13,
                                                  color: Colors.black87,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  note.category ?? 'Kuliah',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),

                                          // Tombol Toggle Pin
                                          IconButton(
                                            icon: Icon(
                                              note.isPinned
                                                  ? Icons.push_pin
                                                  : Icons.push_pin_outlined,
                                              color: note.isPinned
                                                  ? Colors.amber.shade800
                                                  : Colors.black45,
                                              size: 20,
                                            ),
                                            tooltip: note.isPinned
                                                ? 'Lepas sematan'
                                                : 'Sematkan ke atas',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _togglePin(note),
                                          ),
                                          const SizedBox(width: 14),

                                          // Tombol Hapus dengan Konfirmasi (Tugas 1)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Colors.redAccent,
                                              size: 20,
                                            ),
                                            tooltip: 'Hapus Catatan',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => _confirmDelete(note),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Judul Catatan
                                      Text(
                                        note.title,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),

                                      // Isi Catatan (Preview max 3 baris)
                                      Text(
                                        note.content,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade800,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Tugas 3: Tanggal Pembuatan (created_at)
                                      if (note.createdAt != null)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.access_time_rounded,
                                              size: 13,
                                              color: Colors.black45,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              _formatDate(note.createdAt),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
