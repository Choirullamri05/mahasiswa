# Google Apps Script Setup

1. Buka Apps Script untuk spreadsheet Anda.
2. Ganti isi `Code.gs` dengan file [code.gs](./code.gs).
3. Jika script Anda `standalone`, isi `SPREADSHEET_ID`.
4. Pastikan sheet bernama `mahasiswa`.
5. Header sheet harus:
   - `id`
   - `nama`
   - `prodi`
6. Deploy ulang sebagai Web App:
   - `Execute as`: `Me`
   - `Who has access`: `Anyone`
7. Ambil URL deployment yang berakhir dengan `/exec`.
8. Tempel URL itu ke `apiUrl` di Flutter.

Contoh akses:

- Read:
  - `GET /exec`
- Create:
  - `GET /exec?action=create&id=4&nama=Budi&prodi=Informatika`
- Update:
  - `GET /exec?action=update&id=4&nama=Budi%20Baru&prodi=Sistem%20Informasi`
- Delete:
  - `GET /exec?action=delete&id=4`
