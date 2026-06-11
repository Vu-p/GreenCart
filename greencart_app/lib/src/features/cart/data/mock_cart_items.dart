import '../models/cart_item.dart';

const mockCartItems = [
  CartItem(
    productId: 'mock-avocado',
    productName: 'Organic Avocado Pack',
    imageUrl: '',
    unitPrice: 8.40,
    quantity: 2,
    lineTotal: 16.80,
    stock: 12,
  ),
  CartItem(
    productId: 'mock-oat-milk',
    productName: 'Oat Milk Barista',
    imageUrl: '',
    unitPrice: 4.75,
    quantity: 1,
    lineTotal: 4.75,
    stock: 8,
  ),
  CartItem(
    productId: 'mock-eggs',
    productName: 'Farm Eggs',
    imageUrl: '',
    unitPrice: 6.25,
    quantity: 1,
    lineTotal: 6.25,
    stock: 20,
  ),
];
