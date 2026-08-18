# Folder Blocklist

Folder ini **wajib berisi** berkas `.txt` blocklist agar aplikasi dapat
melakukan klasifikasi domain. Berkas aslinya tidak disertakan di repositori
karena berukuran lebih dari 130 MB.

Unduh berkas blocklist terlebih dahulu, lalu letakkan di folder ini:

```
assets/blocklists/
├── adult.txt          (~120 MB)
├── cryptojacking.txt
├── dangerius.txt
├── dating.txt
├── ddos.txt
├── gambling.txt
├── hacking.txt
├── malware.txt
├── phishing.txt
└── warez.txt
```

Format setiap berkas: satu nama domain per baris, tanpa skema dan tanpa
`www.`, misalnya `contoh-domain.tld`.

Sumber dataset: [UT1 Blocklist - Université Toulouse 1 Capitole](https://dsi.ut-capitole.fr/blacklists/).

Petunjuk pengunduhan lengkap ada pada bagian **Blocklist** di
[README utama](../../README.md).

> Jika folder ini kosong, aplikasi tetap berjalan namun setiap domain akan
> diklasifikasikan sebagai `safe` kecuali cocok dengan aturan kustom dari
> panel admin.
