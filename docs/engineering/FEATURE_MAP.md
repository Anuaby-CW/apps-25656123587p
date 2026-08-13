# Feature-to-Code Map

Peta ini membantu agent menemukan ownership implementasi tanpa mencampurkan bukti kode ke PRD.

| Area | Presentation | Domain/use case | Data/core |
|---|---|---|---|
| Auth | `lib/presentation/auth/` | auth contract/model | `lib/data/repositories/auth_repository.dart`, `lib/core/auth/`, `seed_data.dart` |
| Role navigation | `dashboard_shell.dart` | destination policy | `lib/core/routing/app_destination.dart` |
| POS/catalog selection | `lib/presentation/pos/`, `lib/presentation/cart/` | cart models, manual brew pricing | catalog repository/DAO |
| Checkout tunai | `lib/presentation/checkout/` | `checkout_usecase.dart` | `checkout_repository.dart`, checkout logger |
| Orders compatibility | `lib/presentation/orders/` | receive-payment use case | orders/checkout repository |
| Shift/petty cash | POS/settings dialogs dan providers | shift calculation di flow terkait | settings/petty-cash DAO/database |
| Printer/receipt/drawer | settings dan checkout feedback | receipt models/format request | `lib/core/printer/`, printer log repository |
| Dashboard | `dashboard_overview_screen.dart` | report models | reports DAO/repository |
| Transactions | `lib/presentation/transactions/` | order/payment models | reports/orders queries |
| Reports/PDF | `lib/presentation/reports/` | `report_export_usecase.dart` | reports repository/DAO, `report_file_saver.dart` |
| Products | `lib/presentation/products/` | catalog contract/models | catalog repository/DAO |
| Categories | `lib/presentation/categories/` | catalog contract/models | catalog repository/DAO |
| Add-ons | `lib/presentation/addons/` | catalog contract/models | catalog repository/DAO |
| Beans | `lib/presentation/beans/` | pricing/catalog models | catalog repository/DAO |
| Inventory | `lib/presentation/inventory/` | inventory models/rules | catalog repository, inventory/stock movement tables |
| Users | `lib/presentation/users/` | user models/contracts | `user_repository.dart` |
| Audit | `lib/presentation/audit/` | audit models | audit repository/DAO |
| Settings/reset | `lib/presentation/settings/` | reset/settings contracts | settings/reset repository/DAO |
| Theme/design system | screens + `lib/widgets/common/` | — | `lib/theme/` |
| Android bridge | UI/service callers | — | Dart core service, `MainActivity.kt`, manifest |

## Composition root

`lib/presentation/providers/app_providers.dart` merangkai sebagian besar database, DAO, repository, use case, service, dan state global. Sebelum menambah provider:

1. Cari provider/repository/use case yang sudah melayani domain terkait.
2. Tentukan apakah state benar-benar lintas layar.
3. Pertahankan dependency construction di composition root atau file provider feature yang jelas.
4. Hindari duplikasi query/logic pada screen.

## File referensi berisiko tinggi

- `lib/data/database/app_database.dart`: schema, migration, daftar table/DAO.
- `lib/data/database/seed_data.dart`: akun/data bootstrap.
- `lib/domain/usecases/checkout_usecase.dart`: urutan commit dan periferal.
- `lib/data/repositories/checkout_repository.dart`: atomic checkout/persistence.
- `lib/data/database/daos/reset_dao.dart`: destructive data operation.
- `lib/presentation/providers/app_providers.dart`: dependency graph dan state global.
- `lib/core/routing/app_destination.dart`: role/menu policy dan feature flags.
- `android/app/src/main/kotlin/com/talagacoffee/pos/MainActivity.kt`: native bridge.
- `lib/theme/` dan `lib/widgets/common/`: design-system contract.

## Saat lokasi berubah

Perbarui peta ini bila ownership feature berpindah module. Jangan memasukkan line number karena cepat basi; gunakan symbol/file path dan biarkan agent mencari implementasi aktual.

