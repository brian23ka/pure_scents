import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ADMIN PANEL', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.shopping_bag), text: 'ORDERS'),
            Tab(icon: Icon(Icons.analytics), text: 'ANALYTICS'),
            Tab(icon: Icon(Icons.inventory), text: 'INVENTORY'),
            Tab(icon: Icon(Icons.add_box), text: 'ADD PRODUCT'),
            Tab(icon: Icon(Icons.verified), text: 'BRANDS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const OrdersList(),
          const AnalyticsTab(),
          const InventoryList(),
          const AddProductForm(),
          const BrandManagement(),
        ],
      ),
    );
  }
}

class InventoryList extends StatelessWidget {
  const InventoryList({super.key});

  Future<void> _importDefaults(BuildContext context) async {
    final List<Map<String, dynamic>> defaults = [
      {'name': 'Pencil Perfume', 'priceValue': 150, 'priceLabel': 'KSh 150', 'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuz_02kegPqzaSTjlX3VfV31UWGXKvFh4qdg&s'},
      {'name': 'Pocket Spray', 'priceValue': 500, 'priceLabel': 'KSh 500', 'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQYVAZAIo2cNB-56vhstGiUNwgrR-S2jdXvMA&s'},
      {'name': 'Couples Kit', 'priceValue': 250, 'priceLabel': 'KSh 250', 'image': 'https://www.eyeoflove.com/cdn/shop/files/CouplesKitHerHim_4d3f9032-8567-498b-a01c-742a76f32689.jpg?v=1712876833&width=1080'},
      {'name': 'Lavender Mist', 'priceValue': 4500, 'priceLabel': 'KSh 4,500', 'image': 'https://images.unsplash.com/photo-1595981267035-7b04ca84a82d?auto=format&fit=crop&q=80&w=500'},
      {'name': 'Ocean Breeze', 'priceValue': 5200, 'priceLabel': 'KSh 5,200', 'image': 'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&q=80&w=500'},
      {'name': 'Midnight Rose', 'priceValue': 6000, 'priceLabel': 'KSh 6,000', 'image': 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&q=80&w=500'},
      {'name': 'Sandalwood Gold', 'priceValue': 7500, 'priceLabel': 'KSh 7,500', 'image': 'https://images.unsplash.com/photo-1616949755610-8c9bbc08f138?auto=format&fit=crop&q=80&w=500'},
    ];

    try {
      for (var item in defaults) {
        item['inStock'] = true;
        item['timestamp'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('products').add(item);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signature Collection Imported!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No products in database.'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _importDefaults(context),
                  child: const Text('IMPORT SIGNATURE COLLECTION'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var product = snapshot.data!.docs[index];
            var data = product.data() as Map<String, dynamic>;
            bool inStock = data['inStock'] ?? true;
            String? imageUrl = data['image'];

            return Card(
              child: ListTile(
                leading: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image))
                    : const Icon(Icons.image),
                title: Text(data['name'] ?? 'No Name'),
                subtitle: Text(data['priceLabel'] ?? 'No Price'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: inStock,
                      onChanged: (val) => product.reference.update({'inStock': val}),
                      activeColor: const Color(0xFF004D40),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => product.reference.delete(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class BrandManagement extends StatefulWidget {
  const BrandManagement({super.key});

  @override
  State<BrandManagement> createState() => _BrandManagementState();
}

class _BrandManagementState extends State<BrandManagement> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _addBrand() async {
    if (_nameController.text.isEmpty || _urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both name and logo URL')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('brands').add({
        'name': _nameController.text,
        'logo': _urlController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      _nameController.clear();
      _urlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand Added!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  const Text('ADD PARTNER BRAND', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Brand Name', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'Logo Image URL', border: OutlineInputBorder(), hintText: 'https://...')),
                  const SizedBox(height: 15),
                  if (_isLoading) 
                    const CircularProgressIndicator() 
                  else 
                    ElevatedButton(
                      onPressed: _addBrand, 
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white), 
                      child: const Text('SAVE BRAND')
                    ),
                ],
              ),
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('brands').orderBy('timestamp', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var brand = snapshot.data!.docs[index];
                  var data = brand.data() as Map<String, dynamic>;
                  String? logoUrl = data['logo'];
                  
                  return ListTile(
                    leading: logoUrl != null && logoUrl.isNotEmpty
                        ? Image.network(logoUrl, width: 40, height: 40, errorBuilder: (c, e, s) => const Icon(Icons.verified))
                        : const Icon(Icons.verified),
                    title: Text(data['name'] ?? 'Unknown Brand'),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => brand.reference.delete()),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }
}

class AnalyticsTab extends StatelessWidget {
  const AnalyticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        Map<String, int> ordersPerDay = {};
        Map<String, int> completedPerDay = {};
        int totalRevenue = 0;

        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime? date = (data['timestamp'] as Timestamp?)?.toDate();
          if (date == null) continue;

          String dayKey = DateFormat('yyyy-MM-dd').format(date);
          ordersPerDay[dayKey] = (ordersPerDay[dayKey] ?? 0) + 1;

          String status = (data['mpesa_status'] ?? '').toString().toLowerCase();
          if (status.contains('paid') || status.contains('confirmed')) {
            completedPerDay[dayKey] = (completedPerDay[dayKey] ?? 0) + 1;
            String totalStr = data['total']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '0';
            totalRevenue += int.parse(totalStr);
          }
        }

        var sortedDays = ordersPerDay.keys.toList()..sort((a, b) => b.compareTo(a));

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildStatCard('Total Revenue', 'KSh ${NumberFormat('#,###').format(totalRevenue)}', Icons.payments, Colors.green),
            const SizedBox(height: 25),
            const Text('Daily Performance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 15),
            ...sortedDays.map((day) {
              int total = ordersPerDay[day] ?? 0;
              int completed = completedPerDay[day] ?? 0;
              return Card(
                child: ListTile(
                  title: Text(DateFormat('EEEE, MMM dd').format(DateTime.parse(day))),
                  subtitle: Text('Total Orders: $total'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('$completed Completed', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      Text('${total - completed} Pending', style: const TextStyle(color: Colors.orange, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Row(
          children: [
            CircleAvatar(radius: 30, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 30)),
            const SizedBox(width: 25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class OrdersList extends StatelessWidget {
  const OrdersList({super.key});

  Future<void> _updateStatus(String orderId, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({'mpesa_status': status});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) return const Center(child: Text('No orders yet.'));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var order = snapshot.data!.docs[index];
            var data = order.data() as Map<String, dynamic>;
            DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            String status = data['mpesa_status'] ?? 'Pending';
            bool isPaid = status.toLowerCase().contains('paid') || status.toLowerCase().contains('confirmed');

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              child: ExpansionTile(
                title: Text(data['name'] ?? 'Unknown Customer'),
                subtitle: Text('Total: ${data['total']} | ${DateFormat('dd MMM, HH:mm').format(date)}'),
                trailing: Text(status, style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reg No: ${data['reg_no'] ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                        Text('Phone: ${data['phone']}'),
                        Text('Location: ${data['location']}'),
                        Text('Payment: ${data['payment_method']}'),
                        Text('Status: $status'),
                        const Divider(),
                        const Text('ITEMS:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(data['items'] ?? ''),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!isPaid)
                              ElevatedButton.icon(onPressed: () => _updateStatus(order.id, 'PAID / CONFIRMED'), icon: const Icon(Icons.check), label: const Text('MARK AS PAID'), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white)),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(onPressed: () => order.reference.delete(), icon: const Icon(Icons.delete, color: Colors.red), label: const Text('DELETE', style: TextStyle(color: Colors.red))),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class AddProductForm extends StatefulWidget {
  const AddProductForm({super.key});

  @override
  State<AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      int priceValue = int.parse(_priceController.text);

      await FirebaseFirestore.instance.collection('products').add({
        'name': _nameController.text, 
        'priceValue': priceValue, 
        'priceLabel': 'KSh ${NumberFormat('#,###').format(priceValue)}', 
        'image': _urlController.text, 
        'inStock': true, 
        'timestamp': FieldValue.serverTimestamp()
      });
      
      _nameController.clear(); 
      _priceController.clear(); 
      _urlController.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Added!')));
    } catch (e) { 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); 
    } finally { 
      setState(() => _isLoading = false); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text('ADD NEW PRODUCT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 30),
            TextFormField(
              controller: _nameController, 
              decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _priceController, 
              decoration: const InputDecoration(labelText: 'Price (Numeric)', border: OutlineInputBorder()), 
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Price required' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _urlController, 
              decoration: const InputDecoration(labelText: 'Product Image URL', border: OutlineInputBorder(), hintText: 'https://...'),
              validator: (v) => v!.isEmpty ? 'Image URL required' : null,
            ),
            const SizedBox(height: 30),
            if (_isLoading) 
              const CircularProgressIndicator() 
            else 
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: _submit, 
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20)), 
                  child: const Text('ADD PRODUCT')
                )
              ),
          ],
        ),
      ),
    );
  }
}
