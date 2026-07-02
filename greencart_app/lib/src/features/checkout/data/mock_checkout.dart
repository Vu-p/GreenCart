import '../models/delivery_slot.dart';

const deliverySlots = [
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
    label: 'Saturday',
    window: '10:00 AM - 12:00 PM',
    price: 0,
    recommended: false,
  ),
];

const substitutionOptions = [
  'Tự động thay thế bằng món tương tự rẻ hơn hoặc bằng giá',
  'KHÔNG thay thế — Hoàn tiền ngay cho món hết hàng',
  'Gọi điện thoại cho tôi trước khi thay thế',
];
