class DeliverySlot {
  const DeliverySlot({
    required this.label,
    required this.window,
    required this.price,
    required this.recommended,
  });

  final String label;
  final String window;
  final double price;
  final bool recommended;
}
