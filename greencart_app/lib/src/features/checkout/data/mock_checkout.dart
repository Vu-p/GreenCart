import '../models/delivery_slot.dart';

const deliverySlots = [
  DeliverySlot(
    label: 'Today',
    window: '5:00 - 7:00 PM',
    price: 2.90,
    recommended: true,
  ),
  DeliverySlot(
    label: 'Tomorrow',
    window: '8:00 - 10:00 AM',
    price: 1.90,
    recommended: false,
  ),
  DeliverySlot(
    label: 'Saturday',
    window: '10:00 AM - 12:00 PM',
    price: 0,
    recommended: false,
  ),
];

const substitutionOptions = [
  'Replace with similar organic product',
  'Contact me before replacing',
  'Skip unavailable items',
];
