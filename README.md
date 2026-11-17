# Hydra Games – Responsi Pemrograman Aplikasi Mobile

Aplikasi Flutter **Hydra Games** untuk menelusuri daftar game gratis dari FreeToGame API, melihat detail lengkap game, menyimpan koleksi game secara lokal di Library (Hive), dan mengelola sesi pengguna (SharedPreferences).

## Fitur Utama

### 1. Login, Registrasi Lokal, & Session (`SharedPreferences`)
- Input **Email** dan **Password** dengan validasi input kosong, format email, serta panjang password minimal 6 karakter.
- Password tersembunyi secara default dengan tombol **show/hide**.
- Mendukung mode **Login** maupun **Daftar Akun Lokal** (dengan konfirmasi password).
- Menampilkan pesan kesalahan autentikasi secara langsung jika password salah atau email sudah terdaftar saat registrasi.
- Sesi login (`is_logged_in`, `user_email`, `session_token`) disimpan di `SharedPreferences`, sehingga pengguna tidak perlu login ulang setelah aplikasi ditutup dan dibuka kembali.
- Menggunakan `AuthGate` reaktif sehingga pengguna yang belum login selalu diarahkan ke `LoginPage` dan tidak dapat membuka halaman utama.
- Tombol **Logout** pada halaman Profile menghapus sesi login sepenuhnya dan mengarahkan pengguna kembali ke `LoginPage`.

> **Catatan Keamanan Autentikasi (Demo Lokal):**  
> Project ini **belum** terhubung ke Firebase maupun backend server. Sistem autentikasi yang aktif saat ini adalah **autentikasi lokal (demo) berbasis `SharedPreferences`** agar aplikasi dapat langsung dijalankan dan diuji untuk kebutuhan responsi. Ini bukan autentikasi server produksi yang aman.
>
> **Akun Demo Bawaan:**
> - Gmail: `jasson@gmail.com`
> - Password: `123456`
>
> Sesuai ketentuan responsi, Anda juga dapat langsung masuk menggunakan email valid dan password baru (minimal 6 karakter); akun lokal akan otomatis tersimpan dan diverifikasi pada login berikutnya.

### 2. Home (`Browse Games`)
- Mengambil daftar game secara dinamis dari `https://www.freetogame.com/api/games`.
- Menampilkan daftar game menggunakan `ListView.builder` berisi thumbnail, judul, genre, dan platform.
- Dilengkapi pencarian (judul, genre, platform), loading indicator, error view dengan tombol **Coba Lagi**, pull-to-refresh, serta tombol refresh di AppBar.

### 3. Game Detail
- Mengambil detail game dari `https://www.freetogame.com/api/game?id={game_id}` lalu menggabungkannya dengan data ringkas dari `/games` (`Game.mergeDetails`) agar data dasar tidak hilang jika respons detail tidak lengkap atau gagal dimuat.
- Menampilkan hero image, judul, genre, platform, status, release date, publisher, developer, deskripsi, screenshots (dapat diklik untuk pratinjau layar penuh), dan minimum system requirements.
- Tombol **Add to Library** dan **Remove from Library** reaktif berbasis Hive (`ValueListenableBuilder` + `Box.listenable()`).
- Tombol **Buka Halaman Resmi** dan **Profil FreeToGame** menggunakan `url_launcher`.

### 4. Library & Profile Reaktif (`Hive`)
- Data game di Library disimpan secara lokal menggunakan **Hive** (`Box<String>`) sehingga tetap tersimpan setelah aplikasi ditutup dan dibuka kembali.
- `LibraryPage`, `ProfilePage`, `DetailPage`, dan badge pada `MainPage` semuanya menggunakan `ValueListenableBuilder<Box<String>>` dengan `LibraryService.listenable()` (`box.listenable()`).
- Meskipun `MainPage` menggunakan `IndexedStack`, penambahan atau penghapusan game dari Detail maupun Library **langsung terlihat secara real-time** di Library dan jumlah game di Profile tanpa perlu refresh halaman atau aplikasi.

## Cara Menjalankan Project

### Prasyarat
- Flutter SDK (`>= 3.3.0`)
- Koneksi internet untuk mengakses FreeToGame API

### Langkah Menjalankan
1. Ekstrak folder project dan buka di terminal atau VS Code.
2. Ambil dependency:
   ```bash
   flutter pub get
   ```
3. Jalankan pada **Android** (emulator / perangkat fisik):
   ```bash
   flutter run
   ```
4. Atau jalankan pada **Chrome (Flutter Web)**:
   ```bash
   flutter run -d chrome
   ```
5. Jalankan analisis & pengujian otomatis:
   ```bash
   flutter analyze
   flutter test
   ```

## Catatan Flutter Web (CORS & Gambar)
- Endpoint publik FreeToGame (`https://www.freetogame.com/api/...`) umumnya tidak mengirim header `Access-Control-Allow-Origin` untuk browser.
- Pada mode Web (`kIsWeb`), `ApiService` akan mencoba endpoint resmi FreeToGame terlebih dahulu, lalu otomatis fallback ke CORS proxy publik jika browser memblokir request.
- Komponen gambar (`GameNetworkImage`) menggunakan `WebHtmlElementStrategy.fallback` dengan loading indicator dan ikon fallback jika gambar gagal dimuat.
- Jika jaringan lokal memblokir proxy publik saat menguji di Chrome, alternatif pengembangan lokal adalah menjalankan:
  ```bash
  flutter run -d chrome --web-browser-flag "--disable-web-security"
  ```

## Panduan Konfigurasi Firebase Authentication (Opsional)
Jika ke depannya ingin mengganti autentikasi demo lokal menjadi Firebase Authentication:
1. Buat project di [Firebase Console](https://console.firebase.google.com/) dan aktifkan **Authentication → Sign-in method → Email/Password**.
2. Pasang FlutterFire CLI lalu jalankan:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   Perintah ini akan membuat `lib/firebase_options.dart` serta file konfigurasi platform (`android/app/google-services.json`, dll.).
3. Tambahkan package `firebase_core` dan `firebase_auth` ke `pubspec.yaml`, lalu jalankan `flutter pub get`.
4. Inisialisasi Firebase di `lib/main.dart` (`await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);`).
5. Hubungkan metode `login`, `register`, dan `logout` di `lib/services/auth_service.dart` ke `FirebaseAuth.instance`.

## Struktur Project
```text
lib/
├── main.dart                       # Entry point, Hive/Auth init, Theme, AuthGate
├── models/
│   └── game.dart                   # Model Game, JSON parser, mergeDetails()
├── services/
│   ├── api_service.dart            # FreeToGame API + penanganan fallback CORS Web
│   ├── auth_service.dart           # Autentikasi lokal (demo) & sesi SharedPreferences
│   └── library_service.dart        # Penyimpanan Hive + reactive Box.listenable()
├── screens/
│   ├── login_page.dart             # Login & Registrasi lokal dengan validasi & error state
│   ├── main_page.dart              # Bottom NavigationBar + IndexedStack + auth guard
│   ├── home_page.dart              # Daftar game (ListView), pencarian, refresh, error retry
│   ├── detail_page.dart            # Detail game, screenshots, requirements, Add/Remove Library
│   ├── library_page.dart           # Daftar game milik user (reaktif via ValueListenableBuilder)
│   └── profile_page.dart           # Email, jumlah game real-time, Logout
└── widgets/
    ├── game_network_image.dart     # Network image dengan loading, fallback, dukungan Web
    └── game_tile.dart              # Item kartu game untuk Home & Library
```

## Atribusi API
Seluruh data game berasal dari [FreeToGame.com](https://www.freetogame.com/).
