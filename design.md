# NARA Design System Guide

Dokumen ini adalah acuan desain tunggal untuk seluruh UI NARA agar konsisten lintas menu tanpa perlu deskripsi ulang.

## 1. Prinsip Utama
- Konsisten: semua screen wajib pakai token dari `lib/core/theme/*` dan komponen `lib/components/*`.
- Ringan dibaca: hierarchy teks jelas, kontras aman, tidak ramai.
- Sentuhan halus: animasi singkat (tap scale/fade/slide), tidak berlebihan.
- Mobile-first: aman untuk layar kecil; tidak boleh ada teks terpotong.

## 2. Token Wajib

### 2.1 Warna (`NaraColors`)
- Background utama: `NaraColors.background` (`#E8ECF0`)
- Surface card: `NaraColors.surfaceWhite` / `NaraColors.surfaceCard`
- Primary action: `NaraColors.primary` (`#3B82F6`)
- Success/Warning/Danger: `NaraColors.success`, `warning`, `danger`
- Teks: `textPrimary`, `textSecondary`, `textHint`

Aturan:
- Jangan hardcode hex langsung di screen kecuali benar-benar khusus.
- Status warna:
  - Positif/lunas/sukses: `success`
  - Peringatan/tenggat dekat: `warning`
  - Error/gagal/overdue: `danger`

### 2.2 Spacing (`NaraSpacing`)
- Gunakan skala: `xs 4`, `sm 8`, `md 12`, `lg 16`, `xl 20`, `xxl 24`, `xxxl 32`
- Padding layar default: `NaraSpacing.screenPadding` atau `20`

### 2.3 Radius (`NaraRadius`)
- Card default: `md (16)`
- Large card: `lg (20)`
- Chip/Button: `pill (50)`

### 2.4 Typography (`NaraTextStyles`)
- Font: `Poppins`
- Heading: `h1/h2/h3`
- Body: `body`, `bodySmall`
- Metadata: `caption`, `label`
- Nilai uang besar: `amountLarge/amountMedium`

Aturan:
- Semua text user-facing wajib i18n.
- Hindari font size custom jika style yang ada sudah cukup.

## 3. Komponen Wajib Pakai
- Card: `NaraCard`
- Primary CTA: `NaraPrimaryButton`
- Secondary CTA: `NaraSecondaryButton`
- Filter/tab chips: `NaraChip`
- Empty state: `NaraEmptyState`
- Badge kecil: `NaraBadge`
- Notifikasi icon + red dot: `NotificationBellButton`
- Snackbar global: `showAppSnackBar(...)` dari `lib/core/snackbar_utils.dart`

Aturan:
- Dilarang pakai `ScaffoldMessenger.of(context).showSnackBar` langsung.
- Tombol wajib support label panjang (`ellipsis` sudah di komponen).

## 4. Pola Layout Global
- Scaffold background: `NaraColors.background`
- AppBar:
  - Judul ringkas
  - Aksi kanan: `NotificationBellButton` bila relevan
  - Tanpa icon “hamburger” kiri jika tidak ada drawer
- Konten:
  - urutan: summary -> filter -> list/card utama -> aksi
- Bottom navigation:
  - konsisten 4 menu: Home, Transaksi, Perencanaan, Profile

## 5. Pola per Menu

### 5.1 Home
- Fokus: ringkasan cepat, voice card, quick actions, aktivitas terbaru.
- Gunakan `NaraCard` untuk blok informasi.
- Aktivitas bisa dismiss, tampilkan feedback via `showAppSnackBar`.

### 5.2 Transaksi (Pengeluaran / Pemasukan / Utang-Piutang)
- Tab atas wajib konsisten style `NaraChip`.
- FAB/Add:
  - warna dan bentuk konsisten dengan primary app
  - aksi mengikuti tab aktif (contextual add)
- Kartu transaksi:
  - nama, status, nominal, tindakan utama jelas
  - nominal penting pakai style amount + warna status
- Chart:
  - tampil untuk Pengeluaran dan Pemasukan
  - jika kosong tampil placeholder/empty message (jangan hilang total)

### 5.3 Perencanaan (Reminder)
- Filter chips: Semua, Hari ini, Mendatang, Selesai.
- Card reminder:
  - jenis reminder
  - jadwal
  - action row yang jelas (tes/edit/selesai/tunda sesuai mode)
- Jika ada alarm/fake call mode, jangan munculkan popup ganda.

### 5.4 Notifikasi
- Sumber notifikasi: reminder, utang/piutang, transaksi.
- Mendukung unread/read + swipe action.
- Grouping waktu: hari ini, kemarin, minggu ini, lama.
- Bell indicator merah harus sinkron dengan unread feed.

### 5.5 Profile
- Header profil ringkas.
- List menu pakai card/list tile konsisten:
  - Edit profile
  - Notifikasi
  - Settings
  - Laporan
  - Bahasa
  - Backup

### 5.6 Report
- Ringkasan total pemasukan/pengeluaran/saldo.
- Kategori + tren chart mudah dibaca.
- Download/share report beri feedback via `showAppSnackBar`.

### 5.7 Settings
- Semua toggle fitur (termasuk Voice Beta/Confirmation) ada di sini.
- Bahasa/fitur global harus langsung tercermin lintas screen.

## 6. Standar Interaksi & Feedback
- Snackbar:
  - wajib lewat `showAppSnackBar`
  - durasi default 3 detik
  - tidak stack (replace snackbar lama)
- Dialog konfirmasi:
  - gunakan hanya untuk aksi penting (hapus data, apply voice action, dst)
- Haptic/animation:
  - boleh subtle untuk tap utama, jangan berlebihan.

## 7. i18n Rules (ID/EN)
- Semua text user-facing wajib lewat `I18n.t(...)` / key i18n terpusat.
- Dilarang campur hardcoded ID/EN di widget kecuali fallback teknis sementara.
- Label tab/menu harus sinkron bahasa aktif di semua screen.

## 8. Aksesibilitas & Responsif
- Minimum touch target: 44 px.
- Hindari teks terpotong:
  - pakai `Flexible/Expanded`
  - `maxLines: 1` + `TextOverflow.ellipsis` untuk label tombol/chip
- Kontras warna harus terbaca di light/dark theme.

## 9. Definition of Done (UI)
Setiap perubahan UI dianggap selesai jika:
1. Konsisten dengan token + komponen NARA.
2. Tidak ada overflow/clip di layar kecil.
3. i18n ID/EN rapi.
4. Snackbar/dialog sesuai standar.
5. `flutter analyze` bersih untuk file yang diubah.

## 10. Prompt Template (Supaya Tidak Ulang Jelaskan Design)
Gunakan ini saat request ke Codex:

`Gunakan design system di design.md sebagai sumber kebenaran utama. Jangan ubah style dasar, token, dan pola interaksi global kecuali saya minta eksplisit.`

