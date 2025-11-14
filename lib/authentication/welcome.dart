import 'package:flutter/material.dart';
import 'package:safespace_doctor_app/authentication/login_page.dart';
import 'package:safespace_doctor_app/authentication/regesration.dart';
import 'package:safespace_doctor_app/authentication/widgets/welcome_button.dart';





class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.network(
            'https://cpuhivcyhvqayzgdvdaw.supabase.co/storage/v1/object/public/appimages/Untitled%20design%20(12).png', // placeholder
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Welcome text section - pushed down with more flex and top padding
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 40.0,
                      right: 40.0,
                      top: 80.0, // Push content down from top
                    ),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Welcome Back! Doctor',
                              style: TextStyle(
                                fontSize: 36.0,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(
                                  255,
                                  0,
                                  0,
                                  0,
                                ), // Added white color for better visibility
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Healing begins with you.Let’s make care accessible and secure for everyone.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color.fromARGB(
                                  255,
                                  59,
                                  58,
                                  58,
                                ), // Added white color for better visibility
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Buttons section - reduced flex to push up
                Expanded(
                  flex: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40.0,
                      vertical: 20.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start, // Changed from end
                      children: [
                        WelcomeButton(
                          buttonText: 'Login',
                          onTap: LoginPage(),
                          color: Colors.blue,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        WelcomeButton(
                          buttonText: 'Regiter Now',
                          onTap: const RegistrationScreen(),
                          color: Colors.green,
                          textColor: Colors.white,
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
