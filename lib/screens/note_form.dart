import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/note.dart';

class NoteForm extends StatefulWidget {
  final Note? note;

  const NoteForm({super.key, this.note});

  @override
  State<NoteForm> createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController contentController;
  final db = DatabaseHelper.instance;

  // Nilai Tambahan: Kategori Berwarna dengan Ikon Menarik
  final List<Map<String, dynamic>> categoryList = [
    {'name': 'Kuliah', 'icon': Icons.school_rounded, 'color': Colors.indigo},
    {'name': 'Tugas', 'icon': Icons.assignment_rounded, 'color': Colors.teal},
    {'name': 'Ide', 'icon': Icons.lightbulb_rounded, 'color': Colors.amber},
    {'name': 'Pribadi', 'icon': Icons.lock_rounded, 'color': Colors.deepOrange},
    {'name': 'Lainnya', 'icon': Icons.bookmark_rounded, 'color': Colors.purple},
  ];
  late String selectedCategory;

  // Nilai Tambahan: Palet Warna Catatan Estetik (Modern Pastel)
  final List<Color> noteColors = const [
    Color(0xFFFFF9C4), // Kuning Mentari
    Color(0xFFE1BEE7), // Ungu Lavender
    Color(0xFFC8E6C9), // Hijau Mint
    Color(0xFFFFCDD2), // Mawar Pastel
    Color(0xFFBBDEFB), // Biru Langit
    Color(0xFFFFFFFF), // Putih Elegan
  ];
  late Color selectedColor;
  bool isPinned = false;
  bool _isSaving = false;
  int _charCount = 0;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note?.title ?? '');
    contentController = TextEditingController(text: widget.note?.content ?? '');

    if (widget.note != null) {
      selectedCategory = widget.note!.category ?? 'Kuliah';
      selectedColor = widget.note!.color != null
          ? Color(widget.note!.color!)
          : noteColors[0];
      isPinned = widget.note!.isPinned;
    } else {
      selectedCategory = 'Kuliah';
      selectedColor = noteColors[0];
      isPinned = false;
    }

    _updateCounts();
    contentController.addListener(_updateCounts);
  }

  void _updateCounts() {
    final text = contentController.text.trim();
    setState(() {
      _charCount = text.length;
      _wordCount = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  @override
  void dispose() {
    contentController.removeListener(_updateCounts);
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final now = DateTime.now().toIso8601String();

    final note = Note(
      id: widget.note?.id,
      title: titleController.text.trim(),
      content: contentController.text.trim(),
      // Tugas 3: Catat tanggal pembuatan (created_at)
      createdAt: widget.note?.createdAt ?? now,
      // Nilai Tambahan: Kategori, Warna & Pin
      category: selectedCategory,
      color: selectedColor.toARGB32(),
      isPinned: isPinned,
    );

    try {
      if (widget.note == null) {
        await db.insert(note);
      } else {
        await db.update(note);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Gagal menyimpan: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Konfirmasi hapus langsung dari halaman form jika dalam mode edit
  void _deleteFromForm() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Catatan Ini?'),
          ],
        ),
        content: const Text('Catatan yang dihapus tidak dapat dipulihkan kembali.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (widget.note?.id != null) {
                await db.delete(widget.note!.id!);
              }
              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'Hari ini';
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      backgroundColor: selectedColor,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Ubah Catatan' : 'Tulis Catatan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          // Tombol Pin
          IconButton(
            icon: Icon(
              isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              color: isPinned ? Colors.amber.shade900 : Colors.black54,
            ),
            tooltip: isPinned ? 'Lepas Sematan' : 'Sematkan ke Atas',
            onPressed: () => setState(() => isPinned = !isPinned),
          ),
          // Tombol Hapus jika dalam mode edit
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Hapus Catatan',
              onPressed: _deleteFromForm,
            ),
          // Tombol Simpan di AppBar
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.indigo.shade800,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isSaving ? null : _saveNote,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner Status & Info Metadata (Kategori, Tanggal, Counter)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                // Badge Kategori Aktif
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        categoryList.firstWhere(
                          (c) => c['name'] == selectedCategory,
                          orElse: () => categoryList[0],
                        )['icon'] as IconData,
                        size: 14,
                        color: Colors.black87,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        selectedCategory,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPinned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.push_pin, size: 12, color: Colors.brown),
                        SizedBox(width: 3),
                        Text(
                          'Disematkan',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Tugas 3: Tanggal Dibuat
                Text(
                  _formatDate(widget.note?.createdAt),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.black12),

          // Area Form Utama (Judul & Isi Bebas Gangguan)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Input Judul Menawan
                    TextFormField(
                      controller: titleController,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Judul Catatan...',
                        hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black38,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Judul catatan wajib diisi' : null,
                    ),

                    const SizedBox(height: 12),

                    // Input Isi Catatan
                    TextFormField(
                      controller: contentController,
                      maxLines: null,
                      minLines: 12,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ketikkan ide, ringkasan materi, atau tugasmu di sini...',
                        hintStyle: TextStyle(fontSize: 16, color: Colors.black38),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'Isi catatan tidak boleh kosong' : null,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Bar Kreatif: Pemilih Warna & Kategori Cepat
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(235),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Info Kata/Karakter & Label Kategori
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'KATEGORI:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      '$_wordCount kata • $_charCount karakter',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Pilihan Kategori dengan Chip Modern
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: categoryList.map((cat) {
                      final name = cat['name'] as String;
                      final icon = cat['icon'] as IconData;
                      final isSelected = selectedCategory == name;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(
                            icon,
                            size: 15,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          label: Text(name),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          selected: isSelected,
                          selectedColor: Colors.indigo.shade800,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? Colors.indigo.shade800 : Colors.grey.shade300,
                            ),
                          ),
                          onSelected: (val) {
                            if (val) setState(() => selectedCategory = name);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Pilihan Warna Catatan (Palet Lingkaran Estetik)
                Row(
                  children: [
                    const Text(
                      'WARNA:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: noteColors.map((color) {
                          final isSelected = selectedColor.toARGB32() == color.toARGB32();
                          return GestureDetector(
                            onTap: () => setState(() => selectedColor = color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isSelected ? 36 : 30,
                              height: isSelected ? 36 : 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.indigo.shade900 : Colors.black26,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: Colors.indigo.withAlpha(70),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color: Colors.indigo.shade900,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
