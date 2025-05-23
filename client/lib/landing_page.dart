import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:myproject/admin/dashboard.dart';
import 'package:myproject/config/config.dart';
import 'package:myproject/utils/constants.dart';
import 'package:myproject/screen/shop_screen.dart';
import 'package:myproject/screen/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LandingPage extends StatefulWidget {
  final token;
  const LandingPage({@required this.token, Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  late String email = '';
  late String userId = '';
  String role = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _decodeTokenAndFetchUser();
  }

  Future<void> _decodeTokenAndFetchUser() async {
    try {
      Map<String, dynamic> jwtDecodedToken = JwtDecoder.decode(widget.token);
      print('Decoded Token: $jwtDecodedToken');

      setState(() {
        email = jwtDecodedToken['_email']?.toString() ?? 'Unknown';
        userId = jwtDecodedToken['_id']?.toString() ?? '';
      });

      if (userId.isNotEmpty) {
        await _fetchUserRole();
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error decoding token: $e');
      setState(() {
        email = 'Invalid token';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserRole() async {
    try {
      final response = await http.get(
        Uri.parse(AppConfig.getApiUrl('/users/getUserById/$userId')),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userData = responseData['data'];
        print('response data: $responseData');
        setState(() {
          role = userData['role']?.toString().toLowerCase() ?? '';
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching user role: $e');
      setState(() => isLoading = false);
    }
  }

  void _navigateToShop() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ShopScreen()),
    );
  }

  void _navigateToAdminDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminApp()),
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
                            // Email icon
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

                            // Email information
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

                            // Logout button
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
                                  // Handle logout
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

                    // Admin Dashboard Button (conditionally shown)
                    if (role == 'admin')
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ElevatedButton(
                          onPressed: _navigateToAdminDashboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
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
                                'ADMIN DASHBOARD',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.admin_panel_settings,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),

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
