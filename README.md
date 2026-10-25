# 📝 CatatanKu — Aplikasi Catatan Lokal Berbasis SQLite (Flutter)

Aplikasi mobile pencatatan (*Note App*) modern dan responsif yang dibangun menggunakan **Flutter** dengan penyimpanan data lokal persisten menggunakan **SQLite (sqflite)**. Proyek ini dikembangkan untuk memenuhi **Tugas Praktikum 2 — Pemrograman Mobile (Penyimpanan Data Lokal dengan SQLite)** dengan arsitektur bersih, fitur interaktif, dan tampilan antarmuka (UI/UX) ala *Material 3*.

---

## 🚀 Fitur Utama & Tugas Praktikum

Aplikasi ini mencakup seluruh siklus operasi **CRUD (Create, Read, Update, Delete)** serta implementasi tugas modul praktikum:

1. **📋 Tampil Daftar Catatan (Read)**:
   - Menampilkan seluruh catatan yang tersimpan di basis data SQLite lokal.
   - Catatan yang disematkan (*pinned*) otomatis tampil di posisi paling atas.
   - Dilengkapi badge kategori ber-ikon, preview isi catatan, dan waktu pembuatan.

2. **➕ Tambah Catatan Baru (Create)**:
   - Form pembuatan catatan baru dengan validasi input (judul dan isi tidak boleh kosong).
   - Otomatis mencatat waktu pembuatan (`created_at`) dalam format ISO8601.
   - Pilihan kategori dan warna latar catatan.

3. **✏️ Edit Catatan (Update)**:
   - Ketuk kartu catatan pada beranda untuk membuka form pengubahan.
   - Data lama otomatis terisi (*pre-filled*). Perubahan langsung diperbarui di SQLite.

4. **🗑️ Konfirmasi Hapus (Delete — Tugas 1)**:
   - Dilengkapi dialog konfirmasi `AlertDialog` (*"Hapus Catatan?"*) sebelum data benar-benar dihapus.
   - Terdapat tombol **Urungkan (Undo)** pada SnackBar jika pengguna tidak sengaja menghapus.

5. **🔍 Pencarian Real-time (Tugas 2)**:
   - Input pencarian interaktif di header yang mengeksekusi query SQL dengan operator `LIKE` (`title LIKE ? OR content LIKE ?`).
   - Pencarian otomatis memperbarui daftar catatan secara instan tanpa memuat ulang aplikasi.

6. **📅 Pencatatan Tanggal Dibuat (`created_at` — Tugas 3)**:
   - Kolom `created_at` ditambahkan pada tabel SQLite.
   - Menggunakan mekanisme migrasi basis data (`onUpgrade` dengan `ALTER TABLE`) yang aman dan dinamis.
   - Format tanggal ditampilkan ramah pengguna dalam Bahasa Indonesia (contoh: *25 Okt 2026 • 12:00*).

7. **🌟 Fitur Nilai Tambahan (Kategori, Warna & Pin)**:
   - **Kategori**: Pilihan kategori (*Kuliah, Tugas, Ide, Pribadi, Lainnya*) dengan filter tab interaktif pada beranda.
   - **Palet Warna Pastel**: 6 pilihan warna latar catatan (*Kuning Mentari, Ungu Lavender, Hijau Mint, Mawar Pastel, Biru Langit, Putih*).
   - **Sematkan Catatan (Pin)**: Opsi menyematkan catatan penting agar selalu berada di urutan teratas.
   - **Live Word & Character Counter**: Penghitung kata dan karakter otomatis pada form pembuatan catatan.

---

## 🛠️ Teknologi & Pustaka yang Digunakan

- **Framework**: [Flutter](https://flutter.dev/) (Channel stable, Material Design 3)
- **Bahasa Pemrograman**: [Dart](https://dart.dev/)
- **Database Engine**: [SQLite](https://www.sqlite.org/) via package [`sqflite`](https://pub.dev/packages/sqflite)
- **Path Provider**: [`path`](https://pub.dev/packages/path) (penentuan direktori basis data di perangkat)

---

## 📁 Struktur Direktori Proyek

```text
lib/
├── main.dart                  # Titik masuk utama aplikasi (Theme & MaterialApp)
├── db/
│   └── database_helper.dart   # Manajemen koneksi SQLite (Singleton, Migrasi, & Operasi CRUD)
├── models/
│   └── note.dart              # Model entitas Catatan (Serialization toMap & fromMap)
└── screens/
    ├── home_screen.dart       # Layar beranda (Daftar catatan, Pencarian, & Filter)
    └── note_form.dart         # Layar form (Tambah, Edit, Pemilih Kategori & Warna)
```

---

## ⚙️ Prasyarat Menjalankan Aplikasi

Sebelum menjalankan proyek ini di lingkungan lokal Anda, pastikan telah menginstal:

1. **Flutter SDK** (versi >= 3.0.0) — [Panduan Instalasi Flutter](https://docs.flutter.dev/get-started/install)
2. **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart terpasang.
3. **Android Device / Emulator**:
   - Jika menggunakan **HP Android fisik**: Aktifkan *Developer Options* dan *USB Debugging* (pada perangkat Xiaomi/Redmi, aktifkan juga *Install via USB*).
   - Jika menggunakan **Emulator**: Pastikan AVD (Android Virtual Device) telah dikonfigurasi.

---

## 💻 Langkah-Langkah Menjalankan Proyek

1. **Clone Repository ini**:
   ```bash
   git clone <URL_REPOSITORY_ANDA>
   cd flutter_sqlite_demo
   ```

2. **Unduh Dependensi**:
   ```bash
   flutter pub get
   ```

3. **Periksa Perangkat yang Terhubung**:
   ```bash
   flutter devices
   ```

4. **Jalankan Aplikasi**:
   ```bash
   flutter run
   ```
   *(Pilih perangkat Android Anda saat diminta, atau gunakan `flutter run -d <device_id>`)*

---

## 📄 Skema Tabel SQLite

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TEXT,
  category TEXT,
  color INTEGER,
  is_pinned INTEGER DEFAULT 0
);
```

---

*Dikembangkan untuk Praktikum 2 — Pemrograman Mobile (Semester 7).*
