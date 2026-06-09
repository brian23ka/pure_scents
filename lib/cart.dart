import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'order.dart';
import 'auth.dart';

class CartItem {
  final String id;
  final String name;
  final String priceLabel;
  final int priceValue;
  final String image;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.priceValue,
    required this.image,
    this.quantity = 1,
  });
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount {
    int total = 0;
    _items.forEach((key, value) => total += value.quantity);
    return total;
  }

  int get totalAmount {
    var total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.priceValue * cartItem.quantity;
    });
    return total;
  }

  void addItem(String id, String name, String priceLabel, int priceValue, String image) {
    if (_items.containsKey(id)) {
      _items.update(
        id,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          priceLabel: existing.priceLabel,
          priceValue: existing.priceValue,
          image: existing.image,
          quantity: existing.quantity + 1,
        ),
      );
    } else {
      _items.putIfAbsent(
        id,
        () => CartItem(
          id: id,
          name: name,
          priceLabel: priceLabel,
          priceValue: priceValue,
          image: image,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void removeSingleItem(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity > 1) {
      _items.update(
        id,
        (existing) => CartItem(
          id: existing.id,
          name: existing.name,
          priceLabel: existing.priceLabel,
          priceValue: existing.priceValue,
          image: existing.image,
          quantity: existing.quantity - 1,
        ),
      );
    } else {
      _items.remove(id);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'YOUR BAG',
          style: TextStyle(color: Colors.black, letterSpacing: 3, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        const Text('YOUR BAG IS EMPTY', style: TextStyle(letterSpacing: 2, color: Colors.grey)),
                        const SizedBox(height: 30),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('CONTINUE SHOPPING', style: TextStyle(color: Colors.black)),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(25),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items.values.toList()[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 100,
                              height: 130,
                              decoration: BoxDecoration(
                                image: DecorationImage(image: NetworkImage(item.image), fit: BoxFit.cover),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(item.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                                        onPressed: () => cart.removeItem(item.id),
                                      ),
                                    ],
                                  ),
                                  Text(item.priceLabel, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      _quantityButton(Icons.remove, () => cart.removeSingleItem(item.id)),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                      ),
                                      _quantityButton(Icons.add, () => cart.addItem(item.id, item.name, item.priceLabel, item.priceValue, item.image)),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      Text('KSh ${cart.totalAmount}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (userProvider.user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please login to place an order')),
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const OrderScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004D40),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                      ),
                      child: const Text('PROCEED TO CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Free delivery within Egerton',
                    style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                  )
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 35,
      height: 35,
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200)),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 16, color: Colors.black),
        onPressed: onPressed,
      ),
    );
  }
}
