import 'package:flutter/material.dart';
import '../authentication/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  String? _displayName;
  bool _loading = true;
  String? _userId;

  // Mock data for dashboard stats
  final Map<String, dynamic> _stats = {
    'todayAppointments': 5,
    'totalPatients': 124,
    'pendingTasks': 3,
  };

  @override
  void initState() {
    super.initState();
    _initUser();
  }

  Future<void> _initUser() async {
    setState(() {
      _loading = true;
    });

    try {
      final uid = _authService.getCurrentUserId();
      _userId = uid;

      final name = await _authService.fetchDisplayName();
      setState(() {
        _displayName = name;
      });
    } catch (e, st) {
      debugPrint('Error initializing user: $e\n$st');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  String get _greeting {
    if (_loading) return 'Hello Doctor 👋';
    if (_displayName != null && _displayName!.isNotEmpty) {
      final name = _displayName!.trim();
      if (name.toLowerCase().startsWith('dr') || name.toLowerCase().startsWith('doctor')) {
        return 'Hello $name 👋';
      }
      return 'Hello Dr. $name 👋';
    }
    return 'Hello Doctor 👋';
  }

  // Make this method public so it can be called from NavManager
  void refreshData() {
    _initUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Doctor Dashboard"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your dashboard...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Welcome to your medical practice management system",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Grid
                  const Text(
                    "Today's Overview",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Today\'s Appointments',
                        _stats['todayAppointments'].toString(),
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Total Patients',
                        _stats['totalPatients'].toString(),
                        Icons.people,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Pending Tasks',
                        _stats['pendingTasks'].toString(),
                        Icons.assignment,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Available',
                        'Now',
                        Icons.check_circle,
                        Colors.teal,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        'View Appointments',
                        Icons.calendar_today,
                        Colors.blue,
                        () {
                          // Navigate to appointments - tab index 1
                        },
                      ),
                      _buildActionCard(
                        'Manage Patients',
                        Icons.people,
                        Colors.green,
                        () {
                          // Navigate to patients - tab index 2
                        },
                      ),
                      _buildActionCard(
                        'Add Patient',
                        Icons.person_add,
                        Colors.purple,
                        () {
                          // TODO: Navigate to add patient
                        },
                      ),
                      _buildActionCard(
                        'Medical Records',
                        Icons.medical_services,
                        Colors.red,
                        () {
                          // TODO: Navigate to medical records
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Activity
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recent Activity",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActivityItem(
                            'New appointment scheduled',
                            'John Doe - 10:00 AM',
                            Icons.calendar_today,
                            Colors.blue,
                          ),
                          _buildActivityItem(
                            'Patient record updated',
                            'Sarah Wilson',
                            Icons.people,
                            Colors.green,
                          ),
                          _buildActivityItem(
                            'Prescription sent',
                            'Robert Johnson',
                            Icons.medical_services,
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: const Text(
        '2h ago',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}