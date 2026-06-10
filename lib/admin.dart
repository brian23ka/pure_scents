import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(icon: Icon(Icons.inventory), text: 'PRODUCTS'),
            Tab(icon: Icon(Icons.add_box), text: 'ADD PRODUCT'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrdersList(),
          AnalyticsTab(),
          InventoryList(collection: 'products'),
          AddItemForm(collection: 'products', title: 'ADD SIGNATURE PRODUCT'),
        ],
      ),
    );
  }
}

class InventoryList extends StatelessWidget {
  final String collection;
  const InventoryList({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        if (snapshot.data!.docs.isEmpty) return Center(child: Text('No items in $collection.'));

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var item = snapshot.data!.docs[index];
            var data = item.data() as Map<String, dynamic>;
            bool inStock = data['inStock'] ?? true;
            String? imageUrl = data['image'];

            return Card(
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl, 
                          width: 50, 
                          height: 50, 
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.grey),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                title: Text(data['name'] ?? 'No Name'),
                subtitle: Text(data['priceLabel'] ?? 'No Price'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: inStock,
                      onChanged: (val) => item.reference.update({'inStock': val}),
                      activeColor: const Color(0xFF004D40),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => item.reference.delete(),
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

class AddItemForm extends StatefulWidget {
  final String collection;
  final String title;
  const AddItemForm({super.key, required this.collection, required this.title});

  @override
  State<AddItemForm> createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  XFile? _imageFile;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
        _urlController.clear();
      });
    }
  }

  Future<String?> _uploadImage(XFile xFile) async {
    try {
      String fileName = '${widget.collection}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      
      if (kIsWeb) {
        await ref.putData(await xFile.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(xFile.path), SettableMetadata(contentType: 'image/jpeg'));
      }
      
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload an image or paste a valid URL')));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      int priceValue = int.parse(_priceController.text);
      String imageUrl = _urlController.text.trim();

      if (_imageFile != null) {
        String? uploadedUrl = await _uploadImage(_imageFile!);
        if (uploadedUrl != null) {
          imageUrl = uploadedUrl;
        } else {
          throw 'Image upload failed.';
        }
      }

      await FirebaseFirestore.instance.collection(widget.collection).add({
        'name': _nameController.text.trim(), 
        'priceValue': priceValue, 
        'priceLabel': 'KSh ${NumberFormat('#,###').format(priceValue)}', 
        'image': imageUrl, 
        'inStock': true, 
        'timestamp': FieldValue.serverTimestamp()
      });
      
      _nameController.clear(); 
      _priceController.clear(); 
      _urlController.clear();
      setState(() => _imageFile = null);
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.collection.toUpperCase()} Added Successfully!')));
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
            Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 30),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12), 
                        child: kIsWeb 
                          ? Image.network(_imageFile!.path, fit: BoxFit.cover) 
                          : Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                      )
                    : _urlController.text.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12), 
                            child: Image.network(_urlController.text.trim(), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.add_a_photo, size: 40, color: Colors.grey), Text('Tap to upload image', style: TextStyle(color: Colors.grey))],
                          ),
              ),
            ),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _nameController, 
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _priceController, 
              decoration: const InputDecoration(labelText: 'Price (Numeric)', border: OutlineInputBorder()), 
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'Price required' : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _urlController, 
              decoration: const InputDecoration(labelText: 'Or Paste Direct Image URL', border: OutlineInputBorder()),
              onChanged: (v) => setState(() {}),
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
                  child: const Text('SAVE ITEM')
                )
              ),
          ],
        ),
      ),
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
