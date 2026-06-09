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
    const String logoPath = 'lib/assests/Screenshot 2026-06-08 125015.png';

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
      home: const LandingPage(logoPath: logoPath),
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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _shopKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();
  final GlobalKey _homeKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    if (key.currentContext == null) return;
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1590736704728-f4730bb30770?auto=format&fit=crop&q=80&w=800',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.nature, color: Color(0xFF004D40), size: 50),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'In 2026, amidst the vibrant landscapes of Kenya, Pure Scents Ltd was founded on a simple realization: the most profound luxuries are those crafted by nature itself.\n\n'
                'Our journey began in a small garden in Naivasha, where our founder, inspired by the intoxicating aroma of rain-soaked earth and wild jasmine, sought to capture these fleeting moments in a bottle. We believe that a fragrance is more than just a scent; it is a memory, an emotion, and a connection to the soul of the African continent.\n\n'
                'Every ingredient we use is ethically sourced from local farmers. From the sun-drenched roses of the Rift Valley to the deep, resonant sandalwood of the coast, we prioritize sustainability and artisanal excellence. We don\'t just make perfumes; we curate botanical experiences that honor the earth and empower the wearer.',
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
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF004D40)),
              child: Center(
                child: Image.asset(widget.logoPath, height: 100, errorBuilder: (c, e, s) => const Icon(Icons.eco, color: Colors.white, size: 50)),
              ),
            ),
            ListTile(title: const Text('Home'), onTap: () { Navigator.pop(context); _scrollTo(_homeKey); }),
            ListTile(title: const Text('Shop'), onTap: () { Navigator.pop(context); _scrollTo(_shopKey); }),
            ListTile(title: const Text('About'), onTap: () { Navigator.pop(context); _scrollTo(_aboutKey); }),
            ListTile(title: const Text('Contact'), onTap: () { Navigator.pop(context); _scrollTo(_contactKey); }),
            if (userProvider.user != null)
              ListTile(
                title: const Text('My Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
                },
              ),
            if (userProvider.isAdmin)
              ListTile(
                title: const Text('Admin Panel', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminScreen()));
                },
              ),
            ListTile(
              title: Text(userProvider.user == null ? 'Login' : 'Logout'),
              onTap: () {
                Navigator.pop(context);
                if (userProvider.user == null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AuthScreen()));
                } else {
                  userProvider.logout();
                }
              },
            ),
          ],
        ),
      ) : null,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Colors.white.withOpacity(0.9),
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1), width: 1)),
            ),
          ),
          leading: isMobile ? Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF004D40)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ) : null,
          title: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  widget.logoPath,
                  height: isMobile ? 50 : 65,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.eco, color: Color(0xFF004D40)),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 15),
                  const Text(
                    'PURE SCENTS',
                    style: TextStyle(
                      color: Color(0xFF004D40),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                      fontSize: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
          centerTitle: isMobile,
          actions: [
            if (!isMobile) ...[
              _navButton('Home', () => _scrollTo(_homeKey)),
              _navButton('Shop', () => _scrollTo(_shopKey)),
              _navButton('About', () => _scrollTo(_aboutKey)),
              _navButton('Contact', () => _scrollTo(_contactKey)),
              if (userProvider.user != null)
                IconButton(
                  icon: const Icon(Icons.person_outline, color: Color(0xFF004D40)),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen())),
                  tooltip: 'Profile',
                ),
              if (userProvider.isAdmin)
                _navButton('Admin Panel', () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AdminScreen()))),
              _navButton(userProvider.user == null ? 'Login' : 'Logout', () {
                if (userProvider.user == null) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AuthScreen()));
                } else {
                  userProvider.logout();
                }
              }),
            ],
            const SizedBox(width: 10),
            Consumer<CartProvider>(
              builder: (context, cart, child) => Badge(
                label: Text(cart.itemCount.toString()),
                isLabelVisible: cart.itemCount > 0,
                child: IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF004D40)),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            HeroSection(
              key: _homeKey,
              logoPath: widget.logoPath,
              onShopNow: () => _scrollTo(_shopKey),
              onDiscoverStory: _showStoryDialog,
            ),
            FeaturedScents(key: _shopKey),
            const WhyChooseUs(),
            AboutSection(key: _aboutKey),
            NewsletterSection(key: _contactKey),
            Footer(logoPath: widget.logoPath, onContact: () => _scrollTo(_contactKey)),
          ],
        ),
      ),
      floatingActionButton: const ChatBot(),
    );
  }

  Widget _navButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: text == 'Admin Panel' ? Colors.red : Colors.black87,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        child: Text(text),
      ),
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
        response = "You can find our products in the 'Signature Collection' section. We have everything from Pencil Perfumes to luxury Sandalwood Gold!";
      } else if (lowerMsg.contains('delivery') || lowerMsg.contains('shipping')) {
        response = "We offer delivery across Kenya. You can pay via M-Pesa or Pay on Delivery!";
      } else if (lowerMsg.contains('story') || lowerMsg.contains('about')) {
        response = "Pure Scents was founded in 2026 with a focus on organic African botanicals. Click 'Discover Our Story' for more!";
      } else if (lowerMsg.contains('hi') || lowerMsg.contains('hello')) {
        response = "Hello there! Looking for a specific scent today?";
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
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1)],
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
                            color: isBot ? Colors.grey[200] : const Color(0xFF004D40).withOpacity(0.1),
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

class HeroSection extends StatelessWidget {
  final String logoPath;
  final VoidCallback onShopNow;
  final VoidCallback onDiscoverStory;
  const HeroSection({super.key, required this.logoPath, required this.onShopNow, required this.onDiscoverStory});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 800;

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: isMobile ? 550 : 700,
          child: Image.network(
            'https://images.unsplash.com/photo-1470770841072-f978cf4d019e?auto=format&fit=crop&q=80&w=1600',
            fit: BoxFit.cover,
            errorBuilder: _imageErrorWidget,
          ),
        ),
        Container(
          height: isMobile ? 550 : 700,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: isMobile ? Alignment.topCenter : Alignment.centerLeft,
              end: isMobile ? Alignment.bottomCenter : Alignment.centerRight,
              colors: [
                Colors.white,
                Colors.white.withOpacity(0.85),
                Colors.white.withOpacity(isMobile ? 0.3 : 0),
              ],
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            children: [
              Image.asset(logoPath, height: isMobile ? 60 : 80, errorBuilder: (c, e, s) => const Icon(Icons.eco, color: Color(0xFF004D40), size: 40)),
              const SizedBox(height: 30),
              Text(
                'The Art of\nNatural Scent.',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: const Color(0xFF004D40),
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                      fontSize: isMobile ? 45 : 80,
                    ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: 550,
                child: Text(
                  'Handcrafted in Kenya using 100% organic botanical essences. Sustainable luxury for the modern soul.',
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  style: TextStyle(fontSize: isMobile ? 18 : 22, color: Colors.black87, height: 1.6),
                ),
              ),
              const SizedBox(height: 50),
              Wrap(
                alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
                spacing: 20,
                runSpacing: 20,
                children: [
                  ElevatedButton(
                    onPressed: onShopNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004D40),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('SHOP NOW'),
                  ),
                  TextButton(
                    onPressed: onDiscoverStory,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF004D40),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                    ),
                    child: const Text('DISCOVER OUR STORY'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _imageErrorWidget(BuildContext context, Object error, StackTrace? stackTrace) {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.broken_image, color: Color(0xFF004D40), size: 50),
      ),
    );
  }
}

class FeaturedScents extends StatelessWidget {
  const FeaturedScents({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Container(height: 1, width: 100, color: const Color(0xFF004D40)),
          const SizedBox(height: 20),
          const Text(
            'The Signature Collection',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF004D40), letterSpacing: 1),
          ),
          const SizedBox(height: 50),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error loading products: ${snapshot.error}', textAlign: TextAlign.center),
                );
              }
              if (!snapshot.hasData) return const CircularProgressIndicator();
              
              final allProducts = snapshot.data!.docs.map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return data;
              }).toList();

              if (allProducts.isEmpty) {
                return const Text('Add products from Admin Panel to see them here.');
              }

              return Wrap(
                spacing: 30,
                runSpacing: 50,
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
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Container(
                height: 400,
                width: 300,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColorFiltered(
                    colorFilter: inStock ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply) : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                    child: imageUrl != null ? Image.network(
                      imageUrl, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Color(0xFF004D40), size: 50),
                      ),
                    ) : Container(color: Colors.grey[100], child: const Icon(Icons.image_not_supported)),
                  ),
                ),
              ),
              if (!inStock)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(4)),
                    child: const Text('OUT OF STOCK', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 25),
          Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(scent['priceLabel'] ?? 'Price TBD', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('EXPLORE', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
              const SizedBox(width: 10),
              if (inStock)
                ElevatedButton(
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false).addItem(
                      scent['id'],
                      name,
                      scent['priceLabel'] ?? '',
                      scent['priceValue'] ?? 0,
                      imageUrl ?? '',
                    );
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$name added to cart!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004D40),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('ADD TO CART'),
                )
              else
                const Text('NOT AVAILABLE', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
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
      color: const Color(0xFFF9FBF9),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 40,
        runSpacing: 40,
        children: const [
          FeatureItem(icon: Icons.auto_awesome, title: 'ARTISANAL', description: 'Every bottle is handcrafted with precision.'),
          FeatureItem(icon: Icons.eco_outlined, title: 'NATURAL', description: 'Sourced from the heart of African botanicals.'),
          FeatureItem(icon: Icons.history_edu, title: 'LEGACY', description: 'Scents that linger and create lasting memories.'),
        ],
      ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const FeatureItem({super.key, required this.icon, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40, color: const Color(0xFF004D40)),
        const SizedBox(height: 20),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 15),
        SizedBox(width: 250, child: Text(description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5))),
      ],
    );
  }
}

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 100, horizontal: isMobile ? 20 : 80),
      child: Flex(
        direction: isMobile ? Axis.vertical : Axis.horizontal,
        children: [
          Expanded(
            flex: isMobile ? 0 : 1,
            child: Column(
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                const Text('ROOTED IN NATURE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.grey)),
                const SizedBox(height: 20),
                Text('The Essence of Kenya', 
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF004D40))),
                const SizedBox(height: 40),
                Text(
                  'Pure Scents Ltd was born out of a passion for the rich, botanical diversity of East Africa. From the rose farms of Naivasha to the sandalwood forests, we capture the soul of the continent in every bottle.',
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(fontSize: 18, height: 1.8, color: Colors.black87),
                ),
                const SizedBox(height: 30),
                Text(
                  'Every fragrance is a journey, meticulously blended by our master perfumers to ensure a lasting impression that is as unique as you are.',
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  style: const TextStyle(fontSize: 18, height: 1.8, color: Colors.black87),
                ),
              ],
            ),
          ),
          SizedBox(width: isMobile ? 0 : 100, height: isMobile ? 50 : 0),
          Expanded(
            flex: isMobile ? 0 : 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://images.unsplash.com/photo-1557170334-a9632e77c6e4?auto=format&fit=crop&q=80&w=800',
                height: isMobile ? 350 : 600,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 350,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.nature, color: Color(0xFF004D40), size: 50)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NewsletterSection extends StatefulWidget {
  const NewsletterSection({super.key});

  @override
  State<NewsletterSection> createState() => _NewsletterSectionState();
}

class _NewsletterSectionState extends State<NewsletterSection> {
  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  final List<String> _managerIcons = [
    'https://cdn-icons-png.flaticon.com/512/3135/3135715.png', 
    'https://cdn-icons-png.flaticon.com/512/3062/3062329.png', 
    'https://cdn-icons-png.flaticon.com/512/3062/3062319.png', 
    'https://cdn-icons-png.flaticon.com/512/3135/3135768.png', 
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0, viewportFraction: 0.35);
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _managerIcons.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF004D40),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          const Text(
            'PURE SCENTS MANAGERS',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 100,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _managerIcons.length,
              itemBuilder: (context, index) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.network(
                      _managerIcons[index],
                      height: 55,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.account_circle, color: Colors.white, size: 55),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            'FOR SUPPORT',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 4),
          ),
          const SizedBox(height: 20),
          const SelectableText(
            'Call: +254116921099',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
          ),
          const SelectableText(
            'Email: purescents254@gmail.com',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w300, letterSpacing: 1),
          ),
        ],
      ),
    );
  }
}

class Footer extends StatelessWidget {
  final String logoPath;
  final VoidCallback onContact;
  const Footer({super.key, required this.logoPath, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: isMobile ? 20 : 80),
      width: double.infinity,
      child: Column(
        children: [
          const Text('OUR PARTNER BRANDS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 3, color: Colors.grey)),
          const SizedBox(height: 30),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('brands').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error loading brands: ${snapshot.error}', style: const TextStyle(color: Colors.grey, fontSize: 10));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text('Add brand logos from Admin Panel', style: TextStyle(color: Colors.grey, fontSize: 10));
              }
              return Wrap(
                spacing: 50,
                runSpacing: 30,
                alignment: WrapAlignment.center,
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String? logoUrl = data['logo'];
                  if (logoUrl == null) return const SizedBox.shrink();
                  return Opacity(
                    opacity: 0.6,
                    child: Image.network(logoUrl, height: 40, errorBuilder: (c, e, s) => const Icon(Icons.verified)),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 80),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Image.asset(logoPath, height: 70, errorBuilder: (c, e, s) => const Icon(Icons.eco, color: Color(0xFF004D40), size: 40)),
                  const SizedBox(height: 20),
                  const Text('© 2026 23HREE.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
              if (isMobile) const SizedBox(height: 50),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 30,
                runSpacing: 20,
                children: [
                  _footerLink('INSTAGRAM'),
                  _footerLink('FACEBOOK'),
                  _footerLink('TIKTOK'),
                  TextButton(onPressed: onContact, child: const Text('CONTACT US', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 60),
          const Divider(color: Colors.black12),
          const SizedBox(height: 40),
          const Text(
            'MADE IN KENYA WITH ORGANIC BOTANICALS',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2),
      ),
    );
  }
}
