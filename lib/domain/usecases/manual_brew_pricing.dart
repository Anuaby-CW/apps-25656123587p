class ManualBrewPricing {
  ManualBrewPricing._();

  static int priceForBean({
    required int hotPrice,
    required int icePrice,
    required String temperature,
  }) {
    return temperature == 'Ice' ? icePrice : hotPrice;
  }
}
