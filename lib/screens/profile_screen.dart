import 'package:flutter/material.dart';
import 'package:safespace_doctor_app/services/profile_service.dart';
import 'package:safespace_doctor_app/authentication/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  late Future<Doctor> _doctorFuture;

  final TextEditingController _phoneController = TextEditingController();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _doctorFuture = _profileService.getDoctorProfile();
  }

  void _refreshProfile() {
    setState(() {
      _doctorFuture = _profileService.getDoctorProfile();
    });
  }

  Future<void> _pickAndUploadImage() async {
    setState(() => _isUploading = true);
    try {
      await _profileService.pickAndUploadProfilePicture();
      _refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        errorMessage = errorMessage.replaceAll('Exception: ', '');

        // Handle specific error cases
        if (errorMessage.contains('storage/unauthorized')) {
          errorMessage = 'Permission denied. Please try again.';
        } else if (errorMessage.contains('No image selected')) {
          errorMessage = 'Please select an image to upload.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _showEditPhoneDialog(String currentPhone) async {
    _phoneController.text = currentPhone;
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Update Phone Number'),
          content: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'New Phone Number',
              hintText: '+94 XX XXX XXXX',
              helperText: 'Enter a valid phone number with country code',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newPhone = _phoneController.text.trim();
                if (newPhone.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Phone number cannot be empty'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  await _profileService.updatePhone(newPhone);
                  _refreshProfile();
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phone number updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceAll('Exception: ', ''),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _onAvailabilityChanged(bool newValue, Doctor doctor) async {
    try {
      await _profileService.updateAvailability(newValue);
      _refreshProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        _refreshProfile();
      }
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      // The AuthGate handles navigation after signout
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
      ),
      body: FutureBuilder<Doctor>(
        future: _doctorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No profile found.'));
          }

          final doctor = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileHeader(doctor),
                const SizedBox(height: 24),
                _buildInfoCard(doctor),
                const SizedBox(height: 16),
                _buildSettingsCard(doctor),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _logout,
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Doctor doctor) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.teal.withOpacity(0.1),
              backgroundImage:
                  (doctor.profilePictureUrl != null &&
                      doctor.profilePictureUrl!.isNotEmpty)
                  ? NetworkImage(doctor.profilePictureUrl!)
                  : null,
              child:
                  (doctor.profilePictureUrl == null ||
                      doctor.profilePictureUrl!.isEmpty)
                  ? const Icon(Icons.person, size: 60, color: Colors.teal)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: _isUploading
                  ? const SizedBox(
                      height: 28,
                      width: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Material(
                      color: Colors.teal,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _pickAndUploadImage,
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          doctor.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          doctor.category,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF00796B),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(Doctor doctor) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Email'),
            subtitle: Text(doctor.email),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('Phone'),
            subtitle: Text(doctor.phone),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.teal),
              onPressed: () => _showEditPhoneDialog(doctor.phone),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(Doctor doctor) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Available for new patients'),
            subtitle: Text(
              doctor.isAvailable
                  ? 'You are visible to new patients'
                  : 'You are not accepting new patients',
            ),
            value: doctor.isAvailable,
            onChanged: (newValue) => _onAvailabilityChanged(newValue, doctor),
            secondary: const Icon(Icons.event_available_outlined),
            activeColor: Colors.teal,
          ),
        ],
      ),
    );
  }
}
