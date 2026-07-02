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

  String get value => '$label, $window';

  static const standardSlots = [
    DeliverySlot(
      label: 'Today',
      window: '5:00 - 7:00 PM',
      price: 15000,
      recommended: true,
    ),
    DeliverySlot(
      label: 'Tomorrow',
      window: '8:00 - 10:00 AM',
      price: 10000,
      recommended: false,
    ),
    DeliverySlot(
      label: 'Express',
      window: 'Within 45 minutes',
      price: 30000,
      recommended: false,
    ),
  ];
}
