import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<dynamic> acceptedAppointments = [];
  List<dynamic> pendingRequests = [];
  bool loading = true;
  String? errorMessage;
  int? doctorId;

  // Variables for date and time selection
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
    _setupAutoRefresh();
  }

  void _setupAutoRefresh() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        setState(() {});
        _setupAutoRefresh();
      }
    });
  }

  Future<void> _loadDoctorData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      debugPrint('🔄 Starting to load doctor data...');

      // Step 1: Check authentication
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('❌ ERROR: User not logged in');
        setState(() {
          errorMessage = 'User not logged in. Please log in again.';
          loading = false;
        });
        return;
      }

      debugPrint('✅ User authenticated: ${user.email} (${user.id})');

      // Step 2: Get doctor ID
      doctorId = await _getDoctorId(user.email!);
      if (doctorId == null) {
        debugPrint('❌ ERROR: Doctor ID not found');
        setState(() {
          errorMessage = 'Doctor profile not found. Please contact support.';
          loading = false;
        });
        return;
      }

      debugPrint('✅ Doctor ID loaded: $doctorId');

      // Step 3: Load appointments and pending requests
      await _loadAppointments();
      await _loadPendingRequests();

      setState(() {
        loading = false;
      });

      debugPrint('🎉 Data loading completed successfully');
    } catch (e, stackTrace) {
      debugPrint('💥 ERROR loading doctor data: $e');
      debugPrint('Stack trace: $stackTrace');

      setState(() {
        errorMessage = 'Failed to load appointment data: $e';
        loading = false;
      });
    }
  }

  Future<int?> _getDoctorId(String email) async {
    try {
      debugPrint('🔍 Looking up doctor ID for email: $email');

      final doctorResponse = await supabase
          .from('doctors')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      if (doctorResponse != null) {
        final foundDoctorId = doctorResponse['id'] as int;
        debugPrint('✅ Found doctor ID: $foundDoctorId');
        return foundDoctorId;
      } else {
        debugPrint('⚠️ No doctor found with email: $email');

        // Try alternative lookup by user ID if email doesn't work
        final user = supabase.auth.currentUser;
        if (user != null) {
          debugPrint('🔄 Trying lookup by user ID: ${user.id}');

          final doctorById = await supabase
              .from('doctors')
              .select('id')
              .eq('user_id', user.id)
              .maybeSingle();

          if (doctorById != null) {
            final foundDoctorId = doctorById['id'] as int;
            debugPrint('✅ Found doctor ID by user ID: $foundDoctorId');
            return foundDoctorId;
          }
        }

        return null;
      }
    } catch (e) {
      debugPrint('❌ Error looking up doctor ID: $e');
      return null;
    }
  }

  Future<void> _loadAppointments() async {
    try {
      debugPrint('📅 Loading accepted appointments for doctor: $doctorId');

      final appointmentsResponse = await supabase
          .from('appointments')
          .select('*')
          .eq('doctor_id', doctorId!)
          .order('date', ascending: true);

      acceptedAppointments = appointmentsResponse;
      debugPrint('✅ Loaded ${acceptedAppointments.length} appointments');

      for (int i = 0; i < acceptedAppointments.length; i++) {
        final appointment = acceptedAppointments[i];
        debugPrint(
          '  📋 Appointment ${i + 1}: ${appointment['user_name']} on ${appointment['date']} at ${appointment['time']}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading appointments: $e');
      acceptedAppointments = [];
    }
  }

  Future<void> _loadPendingRequests() async {
    try {
      debugPrint('⏳ Loading pending call requests for doctor: $doctorId');

      final callRequestsResponse = await supabase
          .from('call_requests')
          .select('id, user_id, username, email, created_at, status')
          .eq('doctor_id', doctorId!)
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      // Map username to user_name for consistency
      pendingRequests = callRequestsResponse.map((request) {
        final mappedRequest = Map<String, dynamic>.from(request);
        if (!mappedRequest.containsKey('user_name') &&
            mappedRequest.containsKey('username')) {
          mappedRequest['user_name'] = mappedRequest['username'];
        }
        return mappedRequest;
      }).toList();

      debugPrint('✅ Loaded ${pendingRequests.length} pending requests');

      for (int i = 0; i < pendingRequests.length; i++) {
        final request = pendingRequests[i];
        debugPrint(
          '  📋 Request ${i + 1}: ${request['user_name']} (${request['email']}) on ${request['created_at']}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error loading pending requests: $e');
      pendingRequests = [];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        debugPrint('📅 Date selected: $_selectedDate');
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        debugPrint('🕐 Time selected: $_selectedTime');
      });
    }
  }

  void _showScheduleDialog(Map<String, dynamic> request) {
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    debugPrint(
      '📋 Showing schedule dialog for request: ${request['user_name']}',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Schedule Appointment for ${request['user_name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Select Date'),
                    subtitle: Text(
                      _selectedDate != null
                          ? '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}'
                          : 'No date selected',
                    ),
                    onTap: () => _selectDate(context).then((_) {
                      setState(() {});
                    }),
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Select Time'),
                    subtitle: Text(
                      _selectedTime != null
                          ? _selectedTime!.format(context)
                          : 'No time selected',
                    ),
                    onTap: () => _selectTime(context).then((_) {
                      setState(() {});
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (_selectedDate != null && _selectedTime != null)
                      ? () {
                          Navigator.of(context).pop();
                          _acceptRequest(request);
                        }
                      : null,
                  child: const Text('Confirm Appointment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    debugPrint('🔄 _acceptRequest called');
    debugPrint('  Doctor ID: $doctorId');
    debugPrint('  Selected Date: $_selectedDate');
    debugPrint('  Selected Time: $_selectedTime');
    debugPrint('  Request: ${request['user_name']} (${request['email']})');

    // Validation
    if (doctorId == null ||
        _selectedDate == null ||
        _selectedTime == null ||
        request['user_id'] == null) {
      debugPrint('❌ ERROR: Missing required data for appointment scheduling');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: Missing required data for scheduling'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final dateStr =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      final userName =
          request['user_name']?.toString() ??
          request['username']?.toString() ??
          'Unknown Patient';
      final roomName = _generateRoomName(userName);

      debugPrint('📝 Attempting to schedule appointment:');
      debugPrint('  User: $userName');
      debugPrint('  Date: $dateStr');
      debugPrint('  Time: $timeStr');
      debugPrint('  Room: $roomName');

      // Insert appointment
      debugPrint('💾 Inserting appointment into database...');
      final appointmentResult = await supabase.from('appointments').insert({
        'doctor_id': doctorId,
        'user_id': request['user_id'],
        'user_name': userName,
        'date': dateStr,
        'time': timeStr,
        'meeting_room': roomName,
        'status': 'confirmed',
      });
      debugPrint('✅ Appointment inserted successfully: $appointmentResult');

      // Insert patient record
      debugPrint('💾 Inserting patient into patients table...');
      final patientResult = await supabase.from('patients').insert({
        'doctor_id': doctorId,
        'patient_id': request['user_id'],
        'user_name': userName,
        'doctornote':
            'Initial consultation scheduled for $dateStr at ${_selectedTime!.format(context)}',
        'ai_generatednote': 'AI analysis pending after consultation',
      });
      debugPrint('✅ Patient inserted successfully: $patientResult');

      // Handle patient record with upsert logic
      debugPrint('💾 Handling patient record...');
      await _handlePatientRecord(request, dateStr, timeStr);

      // Remove from call requests with robust error handling
      debugPrint('️ Removing from call requests...');
      await _removeFromCallRequests(request);

      // Reset selections
      _selectedDate = null;
      _selectedTime = null;

      // Refresh data
      await _loadDoctorData();

      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment scheduled successfully for $userName'),
            backgroundColor: Colors.green,
          ),
        );
      }

      debugPrint('🎉 Appointment scheduling completed successfully');
    } catch (e, stackTrace) {
      debugPrint('💥 ERROR in _acceptRequest: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePatientRecord(
    Map<String, dynamic> request,
    String dateStr,
    String timeStr,
  ) async {
    if (doctorId == null) {
      debugPrint('❌ Doctor ID is null, skipping patient record creation');
      return;
    }

    final patientData = {
      'doctor_id': doctorId,
      'patient_id': request['user_id'].toString(),
      'doctornote':
          'Initial consultation scheduled for $dateStr at ${_selectedTime!.format(context)}',
      'ai_generatednote': 'AI analysis pending after consultation',
    };

    try {
      // First, try to find existing patient record
      debugPrint('🔍 Looking for existing patient record...');
      final existingPatient = await supabase
          .from('patients')
          .select('id')
          .eq('doctor_id', doctorId!)
          .eq('patient_id', request['user_id'].toString())
          .maybeSingle();

      if (existingPatient != null) {
        // Patient record exists, update it
        debugPrint('📝 Patient record exists, updating...');
        final updateResult = await supabase
            .from('patients')
            .update({
              'doctornote':
                  'Follow-up consultation scheduled for $dateStr at ${_selectedTime!.format(context)}',
              'ai_generatednote': 'AI analysis pending after consultation',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('doctor_id', doctorId!)
            .eq('patient_id', request['user_id'].toString());
        debugPrint('✅ Patient record updated successfully: $updateResult');
      } else {
        // Patient record doesn't exist, try to insert
        debugPrint('➕ No existing patient record, inserting new...');
        try {
          await supabase.from('patients').insert(patientData);
          debugPrint('✅ Patient record inserted successfully');
        } catch (insertError) {
          // Try uppercase table name if lowercase fails
          debugPrint('⚠️ Lowercase table failed, trying uppercase...');
          await supabase.from('Patients').insert(patientData);
          debugPrint('✅ Patient record inserted successfully');
        }
      }
    } catch (patientError) {
      debugPrint('❌ Error handling patient record: $patientError');
      debugPrint(
        '⚠️ Continuing without patient record - appointment is still scheduled',
      );
    }
  }

  Future<void> _removeFromCallRequests(Map<String, dynamic> request) async {
    debugPrint('Request ID: ${request['id']}');

    bool requestRemoved = false;

    try {
      // Method 1: Try to delete the request
      debugPrint('🔄 Attempting to delete request...');
      final deleteResult = await supabase
          .from('call_requests')
          .delete()
          .eq('id', request['id'])
          .select();

      if (deleteResult.isNotEmpty) {
        debugPrint('✅ Request deleted successfully');
        requestRemoved = true;
      } else {
        debugPrint('⚠️ No rows deleted, trying status update...');
      }
    } catch (deleteError) {
      debugPrint('❌ Delete failed: $deleteError');
    }

    // Method 2: If delete didn't work, mark as accepted
    if (!requestRemoved) {
      try {
        debugPrint('🔄 Marking request as accepted...');
        await supabase
            .from('call_requests')
            .update({'status': 'accepted'})
            .eq('id', request['id']);
        debugPrint('✅ Request marked as accepted');
        requestRemoved = true;
      } catch (updateError) {
        debugPrint('❌ Status update failed: $updateError');
      }
    }

    // Method 3: If neither worked, remove from local list manually
    if (!requestRemoved) {
      debugPrint('🔄 Manually removing from local pending list...');
      pendingRequests.removeWhere((req) => req['id'] == request['id']);
      requestRemoved = true;
    }

    if (requestRemoved) {
      debugPrint('✅ Request successfully handled');
    } else {
      debugPrint('⚠️ Could not remove request, but appointment was scheduled');
    }
  }

  String _generateRoomName(String userName) {
    final sanitizedName = userName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .substring(0, userName.length < 10 ? userName.length : 10);

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$sanitizedName-$timestamp';
  }

  bool _isMeetingTimeReady(String date, String time) {
    try {
      final now = DateTime.now();
      final appointmentDateTime = DateTime.parse('$date $time');

      final difference = appointmentDateTime.difference(now).inMinutes;
      return difference.abs() <= 10;
    } catch (e) {
      debugPrint('Error parsing meeting time: $e');
      return false;
    }
  }

  bool _isAppointmentExpired(String date, String time) {
    try {
      final now = DateTime.now();
      final appointmentDateTime = DateTime.parse('$date $time');

      return now.isAfter(appointmentDateTime.add(const Duration(minutes: 50)));
    } catch (e) {
      debugPrint('Error parsing appointment expiry: $e');
      return true;
    }
  }

  List<dynamic> get _nonExpiredAppointments {
    return acceptedAppointments.where((appointment) {
      return !_isAppointmentExpired(appointment['date'], appointment['time']);
    }).toList();
  }

  // Function to start Jitsi meeting
  void _startJitsiMeeting(String patientName, String meetingRoom) {
    try {
      debugPrint(
        '🎥 Starting Jitsi meeting for: $patientName in room: $meetingRoom',
      );

      final jitsiMeet = JitsiMeet();

      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("✅ Conference joined: $url");
        },
        conferenceTerminated: (url, error) {
          debugPrint("❌ Conference terminated: $url, error: $error");
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
        conferenceWillJoin: (url) {
          debugPrint("🔄 Conference will join: $url");
        },
        participantJoined: (email, name, role, participantId) {
          debugPrint("👤 Participant joined: $name ($email)");
        },
        participantLeft: (participantId) {
          debugPrint("👋 Participant left: $participantId");
        },
        audioMutedChanged: (muted) {
          debugPrint("🔇 Audio muted: $muted");
        },
        videoMutedChanged: (muted) {
          debugPrint("📹 Video muted: $muted");
        },
        readyToClose: () {
          debugPrint("🚪 Ready to close");
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      );

      var options = JitsiMeetConferenceOptions(
        room: meetingRoom,
        serverURL: "https://meet.jit.si",
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "subject": "Consultation with $patientName",
          "prejoinPageEnabled": false,
          "disableModeratorIndicator": false,
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "pip.enabled": true,
          "invite.enabled": true,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: "Doctor",
          email: supabase.auth.currentUser?.email ?? "doctor@example.com",
        ),
      );

      jitsiMeet.join(options, listener);
    } catch (e) {
      debugPrint('❌ Error starting Jitsi meeting: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start meeting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nonExpiredAppointments = _nonExpiredAppointments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDoctorData,
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: _buildBody(nonExpiredAppointments),
    );
  }

  Widget _buildBody(List<dynamic> nonExpiredAppointments) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading appointments...'),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                'Error Loading Data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDoctorData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status summary
          Card(
            color: Colors.teal[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.teal[600]),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Appointments',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      Text(
                        '${nonExpiredAppointments.length} scheduled • ${pendingRequests.length} pending',
                        style: TextStyle(color: Colors.teal[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Accepted Appointments Section
          Text(
            'Accepted Appointments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (nonExpiredAppointments.isEmpty)
            Center(
              child: SizedBox(
                width: 3100, // adjust as needed
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 48,
                          color: Colors.teal[400],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No upcoming appointments',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'New appointments will appear here once scheduled',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            ...nonExpiredAppointments.map((appointment) {
              final isReady = _isMeetingTimeReady(
                appointment['date'],
                appointment['time'],
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    appointment['user_name'] ?? 'Unknown Patient',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('📅 Date: ${appointment['date']}'),
                      Text('🕐 Time: ${appointment['time']}'),
                      if (isReady)
                        const Text(
                          '🎥 Meeting ready to start',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: isReady
                        ? () => _startJitsiMeeting(
                            appointment['user_name'] ?? 'Patient',
                            appointment['meeting_room'] ??
                                _generateRoomName(
                                  appointment['user_name'] ?? 'default',
                                ),
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReady ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isReady ? 'Start Meeting' : 'Waiting'),
                  ),
                ),
              );
            }),

          const SizedBox(height: 24),

          // Pending Requests Section
          Text(
            'Pending Requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (pendingRequests.isEmpty)
            Center(
              child: SizedBox(
                width: 3400, // adjust to your preferred width
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    height: 180,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 44,
                      vertical: 2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time,
                            size: 40,
                            color: Colors.teal[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No pending requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: 200,
                          child: Text(
                            'New consultation requests will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            ...pendingRequests.map(
              (request) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(
                    request['user_name'] ??
                        request['username'] ??
                        'Unknown Patient',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Requested: ${DateTime.parse(request['created_at']).toLocal()}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () => _showScheduleDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Schedule'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
