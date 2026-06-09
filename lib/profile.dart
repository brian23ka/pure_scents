import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    final String fullName = userProvider.fullName;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PROFILE')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('Please login to view your profile', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AuthScreen())),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white),
                child: const Text('LOGIN / SIGN UP'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF9),
      appBar: AppBar(
        title: const Text('MY PROFILE', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              userProvider.logout();
              Navigator.of(context).pop();
            },
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(30),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: const Color(0xFF004D40),
                    child: Text(
                      (fullName.isNotEmpty ? fullName[0] : (user.email != null && user.email!.isNotEmpty ? user.email![0] : 'U')).toUpperCase(),
                      style: const TextStyle(fontSize: 35, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 25),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName.isNotEmpty ? fullName : (user.email ?? "User"), 
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF004D40))
                        ),
                        const SizedBox(height: 5),
                        Text(user.email ?? '', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                        const SizedBox(height: 12),
                        _buildBadge(userProvider.isAdmin ? "ADMINISTRATOR" : "LOYAL CUSTOMER"),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(25, 40, 25, 10),
              child: Text('MY ORDER HISTORY', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.grey)),
            ),

            // Orders Stream
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _fallbackOrderStream(user.uid);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(50),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyOrders();
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    return _buildOrderCard(snapshot.data!.docs[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _fallbackOrderStream(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyOrders();
        
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) => _buildOrderCard(snapshot.data!.docs[index]),
        );
      },
    );
  }

  Widget _buildEmptyOrders() {
    return Container(
      padding: const EdgeInsets.all(50),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.black12),
            SizedBox(height: 15),
            Text('No orders found yet.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    String status = (data['mpesa_status'] ?? 'Processing').toString();
    bool isPaid = status.toLowerCase().contains('paid') || status.toLowerCase().contains('confirmed');
    DateTime date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF004D40).withOpacity(0.05), shape: BoxShape.circle),
          child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF004D40)),
        ),
        title: Text(data['items'] ?? 'Perfume Order', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${DateFormat('dd MMM, yyyy').format(date)} • ${data['total']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isPaid ? 'PAID' : 'PENDING',
            style: TextStyle(color: isPaid ? Colors.green : Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                _orderDetailRow('Status:', status),
                _orderDetailRow('Location:', data['location'] ?? 'Not specified'),
                _orderDetailRow('Method:', data['payment_method'] ?? 'N/A'),
                const SizedBox(height: 10),
                const Text('Items Included:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(data['items'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _orderDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF004D40),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }
}
