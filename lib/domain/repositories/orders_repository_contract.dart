/// Domain-layer contract for order management.
///
/// Concrete implementations live in `data/repositories/` and depend on
/// infrastructure details (Drift, etc.).  Feature code should depend only
/// on this contract so that the domain layer stays infrastructure-agnostic.
///
/// **Drift type import** – We import `app_database.dart` for record types
/// such as [OrderRecord].  This is a pragmatic compromise: the generated
/// Drift data-classes are simple value objects and creating mirror DTOs
/// would add boilerplate without meaningful decoupling benefit.
library;

import '../../data/database/app_database.dart'; // for OrderRecord
import '../models/order_models.dart'; // for OrderDetail

// ---------------------------------------------------------------------------
// Contract
// ---------------------------------------------------------------------------

/// Contract that every orders repository must fulfil.
abstract class OrdersRepositoryContract {
  /// Emits the current list of [OrderRecord]s whenever the underlying
  /// data changes.
  Stream<List<OrderRecord>> watchOrders();

  /// Returns the full detail (header + line items) for the given [orderId].
  Future<OrderDetail> detail(String orderId);

  /// Transitions the order identified by [orderId] to the *ready* state.
  Future<void> markReady(String orderId);

  /// Transitions the order identified by [orderId] to the *completed* state.
  Future<void> complete(String orderId);

  /// Cancels the order identified by [orderId].
  Future<void> cancel(String orderId);
}
