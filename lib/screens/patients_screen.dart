import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final List<Map<String, dynamic>> _patients = [];
  final List<Map<String, dynamic>> _allPatients = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<int?> _getDoctorId(String email) async {
    try {
      print('🔍 Looking up doctor ID for email: $email');

      final doctorResponse = await _supabase
          .from('doctors')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (doctorResponse != null) {
        final foundDoctorId = doctorResponse['id'] as int;
        print('✅ Found doctor ID: $foundDoctorId');
        return foundDoctorId;
      } else {
        print('⚠️ No doctor found with email: $email');

        // Try alternative lookup by user ID if email doesn't work
        final user = _supabase.auth.currentUser;
        if (user != null) {
          print('🔄 Trying lookup by user ID: ${user.id}');

          final doctorById = await _supabase
              .from('doctors')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

          if (doctorById != null) {
            final foundDoctorId = doctorById['id'] as int;
            print('✅ Found doctor ID by user ID: $foundDoctorId');
            return foundDoctorId;
          }
        }

        return null;
      }
    } catch (e) {
      print('❌ Error looking up doctor ID: $e');
      return null;
    }
  }

  Future<void> _fetchPatients() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the current doctor's ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔍 DEBUG: Current user: ${user.email} (${user.id})');

      // Get the integer doctor ID
      final doctorId = await _getDoctorId(user.email!);
      if (doctorId == null) {
        print('❌ ERROR: No doctor record found for user');
        throw Exception('Doctor profile not found');
      }

      print('✅ DEBUG: Using doctor ID: $doctorId');

      // Fetch patients for this doctor using the integer ID
      final response = await _supabase
          .from('patients')
          .select()
          .eq('doctor_id', doctorId) // Use integer doctor ID instead of UUID
          .order('created_at', ascending: false);

      if (response != null && response is List) {
        _patients.clear();
        _allPatients.clear();
        
        for (var patient in response) {
          _patients.add({
            'id': patient['patient_id'],
            'name': patient['user_name'] ?? 'Unknown',
            'doctor_note': patient['doctornote'] ?? '',
            'ai_generated_note': patient['ai_generatednote'] ?? '',
            'created_at': patient['created_at'],
            'email': '',
          });
        }
        
        _allPatients.addAll(_patients);
      }
    } catch (e) {
      print('Error fetching patients: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading patients: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPatients(String query) {
    setState(() {
      if (query.isEmpty) {
        _patients.clear();
        _patients.addAll(_allPatients);
      } else {
        _patients.clear();
        _patients.addAll(
          _allPatients.where((patient) =>
              patient['name'].toLowerCase().contains(query.toLowerCase()) ||
              (patient['doctor_note']?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (patient['ai_generated_note']?.toLowerCase().contains(query.toLowerCase()) ?? false)),
        );
      }
    });
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _updateDoctorNote(int patientId, String newNote) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the current doctor's ID
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final doctorId = await _getDoctorId(user.email!);
      if (doctorId == null) {
        throw Exception('Doctor profile not found');
      }

      // Update the doctor note in Supabase
      final response = await _supabase
          .from('patients')
          .update({'doctornote': newNote})
          .eq('patient_id', patientId)
          .eq('doctor_id', doctorId);

      if (response != null) {
        // Update local state
        final patientIndex = _patients.indexWhere((p) => p['id'] == patientId);
        if (patientIndex != -1) {
          setState(() {
            _patients[patientIndex]['doctor_note'] = newNote;
          });
          // Also update allPatients for search functionality
          final allPatientIndex = _allPatients.indexWhere((p) => p['id'] == patientId);
          if (allPatientIndex != -1) {
            _allPatients[allPatientIndex]['doctor_note'] = newNote;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doctor note updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating doctor note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating note: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PatientDetailsBottomSheet(
        patient: patient,
        onUpdateNote: (newNote) => _updateDoctorNote(patient['id'], newNote),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search patients...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterPatients,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _patients.isEmpty
                    ? const Center(
                        child: Text(
                          'No patients found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _patients.length,
                        itemBuilder: (context, index) {
                          final patient = _patients[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal.withOpacity(0.1),
                                child: Icon(
                                  Icons.person,
                                  color: Colors.teal,
                                ),
                              ),
                              title: Text(
                                patient['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  if (patient['doctor_note'] != null && patient['doctor_note'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'Doctor Note: ${patient['doctor_note']}',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (patient['ai_generated_note'] != null && patient['ai_generated_note'].isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'AI Note: ${patient['ai_generated_note']}',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  Text(
                                    'Added: ${_formatDate(patient['created_at'])}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onPressed: () => _showPatientDetails(patient),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewPatient,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _addNewPatient() {
    // TODO: Implement add new patient functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new patient functionality'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class PatientDetailsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Function(String) onUpdateNote;

  const PatientDetailsBottomSheet({
    Key? key,
    required this.patient,
    required this.onUpdateNote,
  }) : super(key: key);

  @override
  State<PatientDetailsBottomSheet> createState() => _PatientDetailsBottomSheetState();
}

class _PatientDetailsBottomSheetState extends State<PatientDetailsBottomSheet> {
  final TextEditingController _doctorNoteController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _doctorNoteController.text = widget.patient['doctor_note'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.patient['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Generated Note Section (Read-only)
                  _buildSectionHeader(
                    title: 'AI Generated Note',
                    icon: Icons.auto_awesome,
                    color: Colors.blue,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Text(
                      widget.patient['ai_generated_note']?.isNotEmpty == true
                          ? widget.patient['ai_generated_note']
                          : 'No AI generated note available',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Doctor Note Section (Editable)
                  Row(
                    children: [
                      _buildSectionHeader(
                        title: 'Doctor Note',
                        icon: Icons.medical_services,
                        color: Colors.teal,
                      ),
                      const Spacer(),
                      if (!_isEditing)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.teal),
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                        ),
                      if (_isEditing) ...[
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () {
                            widget.onUpdateNote(_doctorNoteController.text);
                            setState(() {
                              _isEditing = false;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              _doctorNoteController.text = widget.patient['doctor_note'] ?? '';
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isEditing ? Colors.white : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isEditing ? Colors.teal : Colors.grey.shade300,
                      ),
                    ),
                    child: _isEditing
                        ? TextField(
                            controller: _doctorNoteController,
                            maxLines: 6,
                            decoration: const InputDecoration(
                              hintText: 'Enter your medical notes here...',
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(fontSize: 14, height: 1.4),
                          )
                        : Text(
                            widget.patient['doctor_note']?.isNotEmpty == true
                                ? widget.patient['doctor_note']
                                : 'No doctor note added yet. Tap edit to add notes.',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Patient Information
                  _buildSectionHeader(
                    title: 'Patient Information',
                    icon: Icons.info,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow('Patient ID', widget.patient['id']?.toString() ?? 'N/A'),
                  _buildInfoRow('Added Date', _formatDate(widget.patient['created_at'])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon, required Color color}) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  void dispose() {
    _doctorNoteController.dispose();
    super.dispose();
  }
}