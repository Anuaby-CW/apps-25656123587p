---
name: workspace-file-tree
description: Inspect, analyze, and present Dart & Flutter workspace file structure and package dependencies using dart-mcp-server and workspace exploration tools.
---

# Workspace File-Tree Skill (Dart & Flutter MCP Integration)

Skill ini memberikan panduan untuk memetakan, menjelajahi, dan menganalisis struktur file folder workspace pada proyek Flutter/Dart menggunakan integrasi `dart-mcp-server`.

## MCP Tools Integration (`dart-mcp-server`)

Gunakan tool MCP Dart & Flutter yang relevan untuk mendukung eksplorasi:
- `roots`: Mengelola URI root proyek (`file:///path/to/project`). Pastikan root ditambahkan sebelum analisis.
- `read_package_uris`: Resolusi URI paket Dart (`package:...` atau `package-root:...`) ke file lokal atau dependensi pub cache.
- `rip_grep_packages`: Melakukan pencarian pattern pada paket dependensi proyek.
- `analyze_files`: Menganalisis file Dart untuk mendeteksi error sintaks atau static analysis issue.
- `pub` / `pub_dev_search`: Mencari dan mengelola dependensi `pubspec.yaml`.

## Standar Pemetaan File Tree Flutter Workspace

Dalam proyek Flutter seperti **Talaga Coffee POS**, struktur file dipetakan berdasarkan clean architecture dan aturan repository (`AGENTS.md`):

```
talaga_coffee_pos/
├── android/               # Konfigurasi native Android (MainActivity.kt, AndroidManifest.xml, build.gradle)
├── assets/                # Asset gambar, logo, dan font
├── docs/                  # Dokumentasi produk, arsitektur, testing, dan fitur
│   ├── engineering/       # ARCHITECTURE.md, DATA_MODEL.md, FEATURE_MAP.md, ENGINEERING_RULES.md
│   ├── features/          # FEATURE_FLAGS.md
│   ├── product/           # REQUIREMENTS.md, USER_FLOWS.md
│   ├── prompts/           # IMPLEMENT_FEATURE.md
│   └── quality/           # DEFINITION_OF_DONE.md, TESTING.md
├── lib/                   # Kode sumber aplikasi Dart/Flutter
│   ├── core/              # Utility, konstanta, helper lintas fitur
│   ├── data/              # Database Drift/SQLite, DAO, tabel, DTO, repository implementation
│   ├── domain/            # Model domain, antarmuka/interface repository, use case
│   ├── presentation/      # UI screens, widgets per fitur, state management (Riverpod providers)
│   ├── theme/             # Token warna, tipografi, tema visual (DESIGN.md)
│   ├── widgets/           # Shared UI components lintas fitur
│   ├── app.dart           # Root widget & router setup
│   ├── main.dart          # Entry point aplikasi
│   └── seed_data.dart     # Data awal (bootstrap)
├── test/                  # Unit test & widget test
├── tool/                  # Helper scripts (contoh: prepare_logo_assets.dart)
├── AGENTS.md              # Entry point instruksi permanen AI agent
├── DESIGN.md              # Spesifikasi token visual & UI style guide
├── FEATURES.md            # Status fitur aktif
├── PRD.md                 # Product Requirements Document
├── pubspec.yaml           # Manifest proyek & dependensi Flutter/Dart
└── build.yaml             # Konfigurasi build_runner / Drift generator
```

## Langkah Kerja Saat Menggunakan Skill Ini

1. **Inisialisasi MCP Root**: Panggil `roots` (`command: "add"`) dengan URI workspace.
2. **Eksplorasi File**: Gunakan `list_dir`, `grep_search`, atau `read_package_uris` untuk memetakan direktori target.
3. **Analisis Static**: Gunakan `analyze_files` pada `lib/` untuk memastikan tidak ada issue sebelum/setelah modifikasi.
4. **Verifikasi struktur**: Pastikan penambahan/perubahan file baru sesuai dengan hirarki `lib/` (`core`, `data`, `domain`, `presentation`, `theme`, `widgets`).
