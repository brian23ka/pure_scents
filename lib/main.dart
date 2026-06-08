import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart.dart';
import 'dart:async';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => CartProvider(),
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

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isMobile ? Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF004D40)),
              child: Center(
                child: Image.asset(widget.logoPath, height: 100),
              ),
            ),
            ListTile(title: const Text('Home'), onTap: () { Navigator.pop(context); _scrollTo(_homeKey); }),
            ListTile(title: const Text('Shop'), onTap: () { Navigator.pop(context); _scrollTo(_shopKey); }),
            ListTile(title: const Text('About'), onTap: () { Navigator.pop(context); _scrollTo(_aboutKey); }),
            ListTile(title: const Text('Contact'), onTap: () { Navigator.pop(context); _scrollTo(_contactKey); }),
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
                  height: isMobile ? 50 : 65, // Larger logo
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
          foregroundColor: Colors.black87,
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

    // Simple bot logic
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
        Container(
          width: double.infinity,
          height: isMobile ? 550 : 700,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1615485290382-441e4d0c9cb5?auto=format&fit=crop&q=80&w=1600'),
              fit: BoxFit.cover,
            ),
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
              Image.asset(logoPath, height: isMobile ? 60 : 80), // Very visible logo
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
}

class FeaturedScents extends StatelessWidget {
  const FeaturedScents({super.key});

  @override
  Widget build(BuildContext context) {
    final scents = [
      {'id': '1', 'name': 'Pencil Perfume', 'priceLabel': 'KSh 150', 'priceValue': 150, 'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRuz_02kegPqzaSTjlX3VfV31UWGXKvFh4qdg&s'},
      {'id': '2', 'name': 'Pocket Spray', 'priceLabel': 'KSh 500', 'priceValue': 500, 'image': 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQYVAZAIo2cNB-56vhstGiUNwgrR-S2jdXvMA&s'},
      {'id': '3', 'name': 'Couples Kit', 'priceLabel': 'KSh 250', 'priceValue': 250, 'image': 'https://www.eyeoflove.com/cdn/shop/files/CouplesKitHerHim_4d3f9032-8567-498b-a01c-742a76f32689.jpg?v=1712876833&width=1080'},
      {'id': '4', 'name': 'Lavender Mist', 'priceLabel': 'KSh 4,500', 'priceValue': 4500, 'image': 'https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcTfS7lex7-Gfsn7Cw5h9iii0P3vsAJ7DJSiMZzxl0Bd5Fg6QK6gXMpR966iB_0xKbVpku4AQg8KU--KY7YyRHNsEMijsmHHsyb4n0Iqbb1BM20pduPi_N1Cnw'},
      {'id': '5', 'name': 'Ocean Breeze', 'priceLabel': 'KSh 5,200', 'priceValue': 5200, 'image': 'https://images.unsplash.com/photo-1594035910387-fea47794261f?auto=format&fit=crop&q=80&w=500'},
      {'id': '6', 'name': 'Midnight Rose', 'priceLabel': 'KSh 6,000', 'priceValue': 6000, 'image': 'https://images.unsplash.com/photo-1592945403244-b3fbafd7f539?auto=format&fit=crop&q=80&w=500'},
      {'id': '7', 'name': 'Sandalwood Gold', 'priceLabel': 'KSh 7,500', 'priceValue': 7500, 'image': 'https://images.unsplash.com/photo-1616949755610-8c9bbc08f138?auto=format&fit=crop&q=80&w=500'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: Column(
        children: [
          Container(
            height: 1,
            width: 100,
            color: const Color(0xFF004D40),
          ),
          const SizedBox(height: 20),
          const Text(
            'The Signature Collection',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF004D40), letterSpacing: 1),
          ),
          const SizedBox(height: 50),
          Wrap(
            spacing: 30,
            runSpacing: 50,
            alignment: WrapAlignment.center,
            children: scents.map((scent) => ScentCard(scent: scent)).toList(),
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
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
              child: Image.network(scent['image']!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 25),
          Text(scent['name']!.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(scent['priceLabel']!, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('EXPLORE', style: TextStyle(color: Color(0xFF004D40), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Provider.of<CartProvider>(context, listen: false).addItem(
                    scent['id'],
                    scent['name'],
                    scent['priceLabel'],
                    scent['priceValue'],
                    scent['image'],
                  );
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${scent['name']} added to cart!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004D40),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('ADD TO CART'),
              ),
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
            child: Container(
              height: isMobile ? 350 : 600,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1557170334-a9632e77c6e4?auto=format&fit=crop&q=80&w=800'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12),
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
    'https://cdn-icons-png.flaticon.com/512/1045/1045371.png', 
    'https://cdn-icons-png.flaticon.com/512/3062/3062329.png', 
    'https://cdn-icons-png.flaticon.com/512/3062/3062319.png', 
    'https://cdn-icons-png.flaticon.com/512/3062/3062335.png', 
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
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                children: [
                  Image.asset(logoPath, height: 70), // Clearly visible logo
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
