import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:safespace_doctor_app/authentication/welcome.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _doctorProfile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDoctorProfile();
  }

  Future<void> _fetchDoctorProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'No user logged in';
          _loading = false;
        });
        return;
      }

      // Fetch doctor data from the doctors table using the user's email
      final response = await _supabase
          .from('doctors')
          .select()
          .eq('email', user.email!)
          .single();

      setState(() {
        _doctorProfile = response;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDoctorProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _doctorProfile == null
                  ? const Center(
                      child: Text('No profile data found'),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Profile Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.teal.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.teal,
                                  child: _doctorProfile!['profilepicture'] != null
                                      ? ClipOval(
                                          child: Image.network(
                                            _doctorProfile!['profilepicture'],
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return _buildInitialsAvatar();
                                            },
                                          ),
                                        )
                                      : _buildInitialsAvatar(),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _doctorProfile!['name'] ?? 'No Name',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _doctorProfile!['category'] ?? 'No Specialization',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _doctorProfile!['dominant_state'] ?? 'No hospital info',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Profile Details
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Professional Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildProfileItem('Specialization', _doctorProfile!['category'] ?? 'Not specified'),
                                  _buildProfileItem('Dominant State', _doctorProfile!['dominant_state'] ?? 'Not specified'),
                                  _buildProfileItem('Member Since', _formatDate(_doctorProfile!['created_at'])),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Contact Information
                          Card(
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Contact Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildContactItem(Icons.email, _doctorProfile!['email'] ?? 'No email'),
                                  _buildContactItem(Icons.phone, _doctorProfile!['phone'] ?? 'No phone'),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Actions
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _changePassword,
                                  icon: const Icon(Icons.lock),
                                  label: const Text('Change Password'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.red.shade50, Colors.red.shade100],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200, width: 1),
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: _logout,
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    label: const Text(
                                      'Logout',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildInitialsAvatar() {
    final name = _doctorProfile?['name'] ?? 'D';
    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    return Text(
      initials,
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileItem(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Not available';
    try {
      final DateTime dateTime = date is String ? DateTime.parse(date) : date;
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _editProfile() {
    // TODO: Implement edit profile functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit profile functionality - will open edit form'),
      ),
    );
  }

  void _changePassword() {
    // TODO: Implement change password functionality using Supabase auth
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password functionality - will open password reset'),
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to logout?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You will need to sign in again to access your account.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performLogout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Yes, Logout',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Future<void> _performLogout() async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
          ),
        ),
      ),
    );

    try {
      await _supabase.auth.signOut();
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Logged out successfully'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Redirect to welcome screen after a short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Logout failed: ${e.toString()}'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}