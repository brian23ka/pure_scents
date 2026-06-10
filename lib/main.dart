import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart.dart';
import 'auth.dart';
import 'admin.dart';
import 'profile.dart';
import 'firebase_options.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => CartProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
      ],
      child: const PureScentsApp(),
    ),
  );
}

class PureScentsApp extends StatelessWidget {
  const PureScentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pure Scents Ltd',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF004D40),
          primary: const Color(0xFF004D40),
        ),
        useMaterial3: true,
        fontFamily: 'Georgia',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic)),
    );

    _controller.forward();

    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => 
                const LandingPage(logoPath: 'lib/assests/Screenshot 2026-06-08 125015.png'),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 1000),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.asset(
                      'lib/assests/Screenshot 2026-06-08 125015.png',
                      height: 150,
                      errorBuilder: (c, e, s) => const Icon(Icons.eco, color: Color(0xFF004D40), size: 100),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'PURE SCENTS',
                    style: TextStyle(
                      color: Color(0xFF004D40),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LandingPage extends StatefulWidget {
  final String logoPath;
  const LandingPage({super.key, required this.logoPath});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  int _currentIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ListView(
        children: [
          HeroSection(
            logoPath: widget.logoPath,
            onShopNow: () => setState(() => _currentIndex = 1),
            onDiscoverStory: _showStoryDialog,
          ),
          const FeaturedScents(),
        ],
      ),
      const SingleChildScrollView(child: FeaturedScents()),
      const SingleChildScrollView(child: Column(children: [AboutSection(), WhyChooseUs()])),
      const SingleChildScrollView(child: ContactSection()),
    ];
  }

  void _showStoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        title: const Text(
          'OUR STORY: BORN FROM THE EARTH',
          style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'In 2026, amidst the vibrant landscapes of Kenya, Pure Scents Ltd was founded on a simple realization: the most profound luxuries are those crafted by nature itself.\n\n'
                'Our journey began in a small garden in Naivasha, where our founder, inspired by the intoxicating aroma of rain-soaked earth and wild jasmine, sought to capture these fleeting moments in a bottle.',
                style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(userProvider),
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_open, color: Color(0xFF004D40)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'PURE SCENTS',
          style: TextStyle(
            color: Color(0xFF004D40),
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF004D40)),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CartScreen())),
              ),
            ),
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF004D40),
        unselectedItemColor: Colors.grey[400],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.local_mall_outlined), activeIcon: Icon(Icons.local_mall), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), activeIcon: Icon(Icons.auto_awesome), label: 'About'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Contact'),
        ],
      ),
      floatingActionButton: const ChatBot(),
    );
  }

  Widget _buildDrawer(UserProvider userProvider) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF004D40)),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Image.asset(widget.logoPath, height: 80, errorBuilder: (c, e, s) => const Icon(Icons.eco, color: Colors.white, size: 50))
              )
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
          if (userProvider.isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: Colors.red),
              title: const Text('Admin Panel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminScreen())),
            ),
          const Spacer(),
          ListTile(
            leading: Icon(userProvider.user == null ? Icons.login : Icons.logout),
            title: Text(userProvider.user == null ? 'Login' : 'Logout'),
            onTap: () {
              if (userProvider.user == null) {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AuthScreen()));
              } else {
                userProvider.logout();
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class HeroSection extends StatelessWidget {
  final String logoPath;
  final VoidCallback onShopNow;
  final VoidCallback onDiscoverStory;
  const HeroSection({super.key, required this.logoPath, required this.onShopNow, required this.onDiscoverStory});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 500,
          child: Image.network(
            'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&q=80&w=1600',
            fit: BoxFit.cover,
          ),
        ),
        Container(
          height: 500,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white.withValues(alpha: 0.8), Colors.transparent],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The Art of\nNatural Scent.', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
              const SizedBox(height: 20),
              const Text('Handcrafted in Kenya. Sustainable luxury.', style: TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 40),
              ElevatedButton(onPressed: onShopNow, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF004D40), foregroundColor: Colors.white), child: const Text('SHOP NOW')),
            ],
          ),
        ),
      ],
    );
  }
}

class ChatBot extends StatefulWidget {
  const ChatBot({super.key});

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  bool _isOpen = false;
  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'content': 'Hello! I\'m your Pure Scents assistant. How can I help you today?'}
  ];
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    String userMsg = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMsg});
      _controller.clear();
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      String response = "I'm not sure about that, but you can explore our Signature Collection or contact our support!";
      String lowerMsg = userMsg.toLowerCase();
      
      if (lowerMsg.contains('shop') || lowerMsg.contains('buy') || lowerMsg.contains('price')) {
        response = "You can find our products in the 'Signature Collection' section.";
      } else if (lowerMsg.contains('delivery') || lowerMsg.contains('shipping')) {
        response = "We offer delivery across Kenya. You can pay via M-Pesa or Pay on Delivery!";
      }

      setState(() {
        _messages.add({'role': 'bot', 'content': response});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isOpen)
          Container(
            margin: const EdgeInsets.only(bottom: 16, right: 16),
            width: 300,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1)],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF004D40),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Scent Assistant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        onPressed: () => setState(() => _isOpen = false),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      bool isBot = _messages[index]['role'] == 'bot';
                      return Align(
                        alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isBot ? Colors.grey[200] : const Color(0xFF004D40).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_messages[index]['content']!),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF004D40)),
                        onPressed: _handleSend,
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        FloatingActionButton(
          onPressed: () => setState(() => _isOpen = !_isOpen),
          backgroundColor: const Color(0xFF004D40),
          child: Icon(_isOpen ? Icons.chat_bubble_outline : Icons.chat, color: Colors.white),
        ),
      ],
    );
  }
}

class FeaturedScents extends StatelessWidget {
  const FeaturedScents({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          const Text('The Signature Collection', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
          const SizedBox(height: 30),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final allProducts = snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList();
              if (allProducts.isEmpty) return const Text('No products found.');
              return Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: allProducts.map((scent) => ScentCard(scent: scent)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ScentCard extends StatelessWidget {
  final Map<String, dynamic> scent;
  const ScentCard({super.key, required this.scent});

  @override
  Widget build(BuildContext context) {
    bool inStock = scent['inStock'] ?? true;
    String? imageUrl = scent['image'];
    String name = (scent['name'] ?? 'Untitled Scent').toString();

    return SizedBox(
      width: 160,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: (imageUrl != null && imageUrl.isNotEmpty) 
              ? Image.network(imageUrl, height: 200, width: 160, fit: BoxFit.cover) 
              : Container(height: 200, width: 160, color: Colors.grey[200]),
          ),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
          Text(scent['priceLabel'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (inStock)
            TextButton(
              onPressed: () => Provider.of<CartProvider>(context, listen: false).addItem(scent['id'], name, scent['priceLabel'] ?? '', scent['priceValue'] ?? 0, imageUrl ?? ''),
              child: const Text('ADD TO CART', style: TextStyle(fontSize: 10)),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('OUT OF STOCK', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}

class WhyChooseUs extends StatelessWidget {
  const WhyChooseUs({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Column(
        children: [
          Text('WHY CHOOSE US', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
          SizedBox(height: 20),
          Text('100% Organic African Botanicals', textAlign: TextAlign.center),
          SizedBox(height: 10),
          Text('Every product we create is rooted in ethical sourcing and sustainable practices. We believe in luxury that doesn\'t cost the earth.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Column(
        children: [
          Text('OUR MISSION & VALUES', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF004D40), letterSpacing: 2)),
          SizedBox(height: 25),
          Text(
            'Founded in 2026, Pure Scents Ltd is dedicated to capturing the essence of the Kenyan wilderness. '
            'Every bottle is a journey through our lush forests and vibrant gardens. '
            'We use 100% organic botanicals, sourced sustainably from local farmers in Naivasha and beyond.\n\n'
            'Our mission is to bring the purity of nature to your daily life, one scent at a time. We blend traditional African scent-making techniques with modern sustainable luxury to create something truly unique.\n\n'
            'We pride ourselves on community impact, providing fair wages to our harvesters and supporting local reforestation projects to ensure the biodiversity of Kenya thrives for generations to come.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class ContactSection extends StatelessWidget {
  const ContactSection({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      color: const Color(0xFF004D40),
      child: const Column(
        children: [
          Icon(Icons.contact_support_outlined, color: Colors.white, size: 40),
          SizedBox(height: 20),
          Text('GET IN TOUCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2)),
          SizedBox(height: 30),
          Text('General Inquiries: purescents254@gmail.com', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 10),
          Text('Support Contact: +254 116 145544', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 10),
          Text('Wholesale: sales.purescents@gmail.com', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 20),
          Text('Address: Nairobi, Kenya\nScent Tower, 4th Floor', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          SizedBox(height: 40),
          Text('Follow us for updates: @PureScentsKE', style: TextStyle(color: Colors.white38, fontSize: 12)),
          SizedBox(height: 10),
          Text('Available Mon-Sat: 8am - 6pm', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
