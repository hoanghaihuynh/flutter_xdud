import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:myproject/utils/constants.dart';
import 'package:myproject/screen/shop_screen.dart';
import 'package:myproject/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LandingPage extends StatefulWidget {
  final token;
  const LandingPage({@required this.token, Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late String email = '';

  @override
  void initState() {
    super.initState();
    try {
      Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
      print('Decoded Token: $jwtDecodedToken');
      email = jwtDecodedToken.containsKey('_email')
          ? jwtDecodedToken['_email'].toString()
          : 'Unknown';
    } catch (e) {
      print('Error decoding token: $e');
      email = 'Invalid token';
    }
  }

  void _navigateToShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShopScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0.0,
              right: -70.0,
              child: Image.asset("assets/images/img_3.png"),
            ),
            Positioned(
              top: 0.0,
              left: 0.0,
              width: MediaQuery.of(context).size.width,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                height: MediaQuery.of(context).size.height,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 60),

                    // Email Card
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(right: 60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Biểu tượng email
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: kTextColor1.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.email_outlined,
                                color: kTextColor1,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),

                            // Thông tin email
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Your Email",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: kTextColor1,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),

                            // Nút đăng xuất
                            IconButton(
                              icon: Icon(Icons.logout, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Logout"),
                                    content: Text("Are you sure about that?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text("Cancel"),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text("Logout",
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  // Xử lý đăng xuất
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.remove('token');
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => LoginScreen()),
                                  );
                                }
                              },
                              tooltip: 'Đăng xuất',
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 80),
                    Text(
                      "Shop Best\nCoffee\nTown",
                      style: TextStyle(
                          fontSize: 35,
                          height: 1.3,
                          color: kTextColor1,
                          fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Experience the best taste of coffee with us exclusively ",
                      style: TextStyle(
                          fontSize: 18, height: 1.8, color: Colors.white),
                    ),

                    SizedBox(height: 40),

                    // Shop Now Button
                    ElevatedButton(
                      onPressed: _navigateToShop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kTextColor1,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'SHOP NOW',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
