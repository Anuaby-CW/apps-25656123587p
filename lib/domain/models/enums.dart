enum UserRole {
  admin,
  cashier;

  static UserRole fromDb(String value) => value == admin.name ? admin : cashier;

  String get label => switch (this) {
    admin => 'Admin',
    cashier => 'Kasir',
  };
}

enum OrderType {
  dineIn,
  takeAway;

  String get label => switch (this) {
    dineIn => 'Dine In',
    takeAway => 'Take Away',
  };

  static OrderType fromDb(String value) =>
      value == takeAway.name ? takeAway : dineIn;
}

enum OrderStatus {
  draft,
  preparing,
  ready,
  completed,
  cancelled;

  static OrderStatus fromDb(String value) => OrderStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => preparing,
  );

  String get label => switch (this) {
    draft => 'Draf',
    preparing => 'Sedang disiapkan',
    ready => 'Siap',
    completed => 'Selesai',
    cancelled => 'Dibatalkan',
  };
}

enum PaymentStatus {
  unpaid,
  paid,
  refunded;

  static PaymentStatus fromDb(String value) => PaymentStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => unpaid,
  );

  String get label => switch (this) {
    unpaid => 'Belum lunas',
    paid => 'Lunas',
    refunded => 'Dikembalikan',
  };
}

enum PaymentMethod {
  cash,
  qris;

  /// Stable values accepted from persisted payment rows.
  ///
  /// Older app versions stored the Indonesian display label (`Tunai`). New
  /// writes use the enum name (`cash`) so changing UI copy cannot break
  /// financial queries.
  static const cashDbValues = <String>['cash', 'Tunai'];

  static PaymentMethod fromDb(String value) => switch (value) {
    'qris' => qris,
    _ => cash,
  };

  String get label => this == cash ? 'Tunai' : 'QRIS (Coming Soon)';
}

enum PaperSizeSetting {
  mm58,
  mm80;

  String get label => switch (this) {
    mm58 => '58 mm',
    mm80 => '80 mm',
  };

  static PaperSizeSetting fromDb(String value) =>
      value == mm80.name ? mm80 : mm58;
}
