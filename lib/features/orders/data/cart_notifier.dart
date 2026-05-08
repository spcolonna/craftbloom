import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final String name;
  final double unitPrice;
  final String priceUnit;
  final String imageUrl;
  final bool isPackage;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.priceUnit,
    required this.imageUrl,
    required this.isPackage,
    this.quantity = 1,
  });

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        name: name,
        unitPrice: unitPrice,
        priceUnit: priceUnit,
        imageUrl: imageUrl,
        isPackage: isPackage,
        quantity: quantity ?? this.quantity,
      );

  double get subtotal => unitPrice * quantity;
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addOrIncrement(CartItem item) {
    final idx = state.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state);
      updated[idx] = state[idx].copyWith(quantity: state[idx].quantity + 1);
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void decrement(String id) {
    final idx = state.indexWhere((i) => i.id == id);
    if (idx < 0) return;
    final updated = List<CartItem>.from(state);
    if (state[idx].quantity <= 1) {
      updated.removeAt(idx);
    } else {
      updated[idx] = state[idx].copyWith(quantity: state[idx].quantity - 1);
    }
    state = updated;
  }

  void remove(String id) {
    state = state.where((i) => i.id != id).toList();
  }

  void clear() => state = [];

  double get total => state.fold(0.0, (sum, i) => sum + i.subtotal);
  int get itemCount => state.fold(0, (sum, i) => sum + i.quantity);
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);
