---
name: Aqua Wood POS Design System (Lumina POS)
project_id: 11729496503735960631
colors:
  surface: '#131315'
  surface-dim: '#131315'
  surface-bright: '#39393b'
  surface-container-lowest: '#0e0e10'
  surface-container-low: '#1b1b1d'
  surface-container: '#1f1f21'
  surface-container-high: '#2a2a2c'
  surface-container-highest: '#353437'
  on-surface: '#e4e2e4'
  on-surface-variant: '#c1c6d5'
  inverse-surface: '#e4e2e4'
  inverse-on-surface: '#303032'
  outline: '#8b919e'
  outline-variant: '#414753'
  surface-tint: '#aac7ff'
  primary: '#aac7ff'
  on-primary: '#002f65'
  primary-container: '#0066cc'
  on-primary-container: '#dfe8ff'
  inverse-primary: '#005cba'
  secondary: '#a1d494'
  on-secondary: '#0a3909'
  secondary-container: '#23501e'
  on-secondary-container: '#90c283'
  tertiary: '#e1c299'
  on-tertiary: '#402d10'
  tertiary-container: '#7c6442'
  on-tertiary-container: '#ffe4c1'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d7e3ff'
  primary-fixed-dim: '#aac7ff'
  on-primary-fixed: '#001b3e'
  on-primary-fixed-variant: '#00458e'
  secondary-fixed: '#bcf0ae'
  secondary-fixed-dim: '#a1d494'
  on-secondary-fixed: '#002201'
  on-secondary-fixed-variant: '#23501e'
  tertiary-fixed: '#feddb3'
  tertiary-fixed-dim: '#e1c299'
  on-tertiary-fixed: '#281801'
  on-tertiary-fixed-variant: '#584324'
  background: '#131315'
  on-background: '#e4e2e4'
  surface-variant: '#353437'
  lake-blue: '#0A2647'
  moss-green: '#2D5A27'
  glass-fill: 'rgba(255, 255, 255, 0.08)'
  glass-stroke: 'rgba(255, 255, 255, 0.12)'
  wood-accent: '#8B5A2B'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  headline-md:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-lg:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.05em
  label-md:
    fontFamily: Hanken Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  base: 8px
  gutter: 24px
  margin-x: 32px
  margin-y: 24px
  card-padding: 20px
---

# Talaga Coffee POS — Aqua Wood & Glassmorphic Design System

> **Project ID Stitch:** `11729496503735960631`  
> **Nama Sistem:** Aqua Wood POS Design System (Lumina POS)  
> **Bahasa Visual:** Apple-inspired Minimalism + Glassmorphic Depth + Warm Wood Accents  
> **Karakter Utama:** Modern, tactile, clean, dan Gen-Z ready dengan kontras legibilitas tinggi.  

---

## 1. Brand & Style Identity

Sistem desain ini dirancang untuk memberikan pengalaman retail POS modern yang menggabungkan estetika **Apple-inspired minimalism** dengan model kedalaman **Glassmorphism** transparan serta aksen fisik **Warm Wood**.

### Pilar Desain:
1. **Glassmorphism Layering:** Komponen menggunakan permukaan frosted glass transparan (`rgba(255, 255, 255, 0.08)`) dengan border bertekstur cahaya (`rgba(255, 255, 255, 0.12)`).
2. **Biophilic Gradient Anchor:** Latar belakang menggunakan gradien alami dari `Lake Blue (#0A2647)` ke `Moss Green (#2D5A27)` untuk suasana tenang.
3. **Tactile Wood Affordance:** Tombol aksi utama (seperti *Bayar* / *Selesaikan Transaksi*) menggunakan aksen kayu hangat (`#8B5A2B`), memberikan kesan fisik yang jelas dan mudah dikenali.
4. **Soft Pill Geometry:** Menggunakan sudut membulat yang ekstrem (`rounded-full` / `rounded-xl`) untuk interaksi sentuh yang nyaman pada perangkat tablet dan seluler.

---

## 2. Palet Warna (Daftar Warna Hex & Semantik)

### Fondasi Utama
| Token Warna | Nilai Hex / RGBA | Peran / Penggunaan |
|---|---|---|
| `background` / `surface` | `#131315` | Latar belakang dasar mode gelap |
| `lake-blue` | `#0A2647` | Aksen gradien latar kiri-atas |
| `moss-green` | `#2D5A27` | Aksen gradien latar kanan-bawah / state sukses |
| `wood-accent` | `#8B5A2B` | Tombol konversi / aksi fisik utama (*Bayar*, *Cetak*) |
| `glass-fill` | `rgba(255, 255, 255, 0.08)` | Isian permukaan frosted card |
| `glass-stroke` | `rgba(255, 255, 255, 0.12)` | Line border pada kartu glass |

### Warna Primer & Kontainer
| Token Warna | Nilai Hex | Peran / Penggunaan |
|---|---|---|
| `primary` | `#aac7ff` | Teks primer pada permukaan gelap / indikator aktif |
| `on-primary` | `#002f65` | Teks di atas warna primary |
| `primary-container` | `#0066cc` | Kontainer aksi aktif / seleksi kategori |
| `on-primary-container` | `#dfe8ff` | Teks di atas primary container |
| `inverse-primary` | `#005cba` | Variasi kontras inversi primary |

### Warna Sekunder & Tersier
| Token Warna | Nilai Hex | Peran / Penggunaan |
|---|---|---|
| `secondary` | `#a1d494` | Warna hijau aksen sekunder / badge positif |
| `on-secondary` | `#0a3909` | Teks di atas warna sekunder |
| `secondary-container` | `#23501e` | Kontainer sekunder / state hijau murni |
| `on-secondary-container` | `#90c283` | Teks di atas secondary container |
| `tertiary` | `#e1c299` | Warna kayu krem / sorotan elemen sekunder |
| `tertiary-container` | `#7c6442` | Kontainer cokelat kayu hangat |
| `on-tertiary-container` | `#ffe4c1` | Teks di atas tertiary container |

### Warna Netral & Permukaan (Surface Containers)
| Token Warna | Nilai Hex | Peran / Penggunaan |
|---|---|---|
| `surface-dim` | `#131315` | Permukaan redup |
| `surface-bright` | `#39393b` | Permukaan terang/terbuka |
| `surface-container-lowest` | `#0e0e10` | Lapisan kontainer terendah |
| `surface-container-low` | `#1b1b1d` | Lapisan kontainer bawah |
| `surface-container` | `#1f1f21` | Kartu permukaan umum |
| `surface-container-high` | `#2a2a2c` | Kartu permukaan tinggi / modal |
| `surface-container-highest` | `#353437` | Kartu permukaan tertinggi |
| `on-surface` | `#e4e2e4` | Teks utama pada permukaan |
| `on-surface-variant` | `#c1c6d5` | Teks sekunder / keterangan label |
| `outline` | `#8b919e` | Border default kontrol & input |
| `outline-variant` | `#414753` | Pemisah horizontal / divider |

### Warna Error & Alert
| Token Warna | Nilai Hex | Peran / Penggunaan |
|---|---|---|
| `error` | `#ffb4ab` | Teks peringatan / bahaya |
| `on-error` | `#690005` | Teks di atas error |
| `error-container` | `#93000a` | Background status stok minimum / bahaya |
| `on-error-container` | `#ffdad6` | Teks di atas error container |

---

## 3. Gaya Teks & Tipografi

Menggunakan strategi dual-font: **Hanken Grotesk** untuk judul/label modern dan **Inter** untuk keterbacaan data transaksi yang optimal.

| Token Tipografi | Font Family | Size | Weight | Line Height | Letter Spacing | Peruntukan Utama |
|---|---|---:|---:|---:|---:|---|
| `display-lg` | Hanken Grotesk | 48px | Bold (700) | 56px | -0.02em | Nominal total bayar / Hero metric |
| `headline-lg` | Hanken Grotesk | 32px | SemiBold (600) | 40px | -0.01em | Judul halaman utama (e.g. *Dashboard*) |
| `headline-lg-mobile` | Hanken Grotesk | 24px | SemiBold (600) | 32px | 0 | Judul halaman pada layar handphone |
| `headline-md` | Hanken Grotesk | 24px | SemiBold (600) | 32px | 0 | Judul seksi kartu / Workbench |
| `body-lg` | Inter | 18px | Regular (400) | 28px | 0 | Teks deskripsi utama / Item terpilih |
| `body-md` | Inter | 16px | Regular (400) | 24px | 0 | Teks bodi standar / Nama produk |
| `label-lg` | Hanken Grotesk | 14px | SemiBold (600) | 20px | 0.05em | Label tombol / Tag kategori |
| `label-md` | Hanken Grotesk | 12px | Medium (500) | 16px | 0 | Metadata kecil / Chip info / Eyebrow |

---

## 4. Sudut Membulat (Border Radius)

Bentuk komponen menggunakan kelengkungan yang dominan dan ramah disentuh (`Pill-shaped`).

| Token Radius | Nilai Rem | Nilai Pixel | Penggunaan Utama |
|---|---|---|---|
| `sm` | `0.5rem` | 8px | Kontrol kecil, badge status, & tag internal |
| `DEFAULT` | `1.0rem` | 16px | Input field & inset gambar produk |
| `md` | `1.5rem` | 24px | Kartu produk, panel kaca, & kontainer modal |
| `lg` | `2.0rem` | 32px | Modal dialog besar & bottom sheet |
| `xl` | `3.0rem` | 48px | Kontainer utama workspace |
| `full` | `9999px` | Pill Radius | Tombol aksi utama, chip kategori, & FAB |

---

## 5. Spacing & Panduan Layout

### Skala Spacing:
- **Base Unit:** `8px`
- **Gutter:** `24px`
- **Card Internal Padding:** `20px` (`card-padding`)
- **Margin Horizontal (X):** `32px` (`margin-x`)
- **Margin Vertikal (Y):** `24px` (`margin-y`)

### Struktur Grid & Adaptivitas:
1. **Desktop & Tablet Landscape (12 Kolom):**
   - **Katalog Produk:** Mengisi `8 kolom` di sisi kiri.
   - **Panel Keranjang / Transaksi:** Fixed `4 kolom` di sisi kanan (`360–400dp`).
   - **Margin perbatasan:** Safe area minimum 24px di sekeliling layar.
2. **Phone Portrait (Single Column Flow):**
   - Layout ditumpuk secara vertikal (1 kolom).
   - Bottom Dock / Floating Cart Bar melayang di atas konten dengan jarak 16px dari bawah.
3. **Elevasi Glassmorphism & Depth:**
   - **Base Layer:** Background `#131315` atau gradien `Lake Blue` ke `Moss Green`.
   - **Level 1 (Card):** Background `rgba(255, 255, 255, 0.08)` dengan `backdrop-filter: blur(20px)` dan border `1px solid rgba(255, 255, 255, 0.12)`.
   - **Level 2 (Modal / Overlay):** Transparansi lebih tinggi dengan `backdrop-filter: blur(40px)` dan bayangan lembut `0px 20px 40px rgba(0, 0, 0, 0.3)`.

---

## 6. Komponen Utama & Pola Interaksi

- **Tombol Utama (Primary Action):** Berbentuk *Pill* (`rounded-full`) dengan warna `wood-accent (#8B5A2B)` dan teks putih tebal. Memberikan respons haptic visual saat ditekan (scale `0.98x`).
- **Glass Card Container:** Menggunakan radius `24px (md)` dengan border stroke berkilau di sisi atas/kiri.
- **Search & Input:** Menggunakan isian glass transparan dengan border `outline (#8b919e)` 1px yang menebal menjadi 2px warna `primary (#aac7ff)` saat fokus.
- **Category Chips:** Berbentuk pill glass; chip aktif berganti warna menjadi `primary-container (#0066cc)` dengan teks `on-primary-container`.
