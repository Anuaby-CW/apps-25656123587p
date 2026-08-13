/// Compile-time switches for features that are preserved but disabled by
/// default. Enable a feature with `--dart-define=<key>=true`.
abstract final class FeatureFlags {
  static const customerNameShortcut = bool.fromEnvironment(
    'FEATURE_CUSTOMER_NAME_SHORTCUT',
    defaultValue: false,
  );

  static const tableNumber = bool.fromEnvironment(
    'FEATURE_TABLE_NUMBER',
    defaultValue: false,
  );

  static const payLater = bool.fromEnvironment(
    'FEATURE_PAY_LATER',
    defaultValue: false,
  );

  static const ordersQueue = bool.fromEnvironment(
    'FEATURE_ORDERS_QUEUE',
    defaultValue: false,
  );

  static const adminPosAccess = bool.fromEnvironment(
    'FEATURE_ADMIN_POS_ACCESS',
    defaultValue: false,
  );

  static const cancelledOrdersReport = bool.fromEnvironment(
    'FEATURE_CANCELLED_ORDERS_REPORT',
    defaultValue: false,
  );

  static const inventoryManagementSetting = bool.fromEnvironment(
    'FEATURE_INVENTORY_MANAGEMENT_SETTING',
    defaultValue: false,
  );
}
