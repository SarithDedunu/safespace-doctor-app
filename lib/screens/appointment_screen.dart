import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final doctorData = await supabase
          .from('doctors')
          .select('id')
          .eq('email', user.email!)
          .single();

      doctorId = doctorData['id'];

      final accepted = await supabase
          .from('appointments')
          .select('*')
          .eq('doctor_id', doctorId!)
          .order('date', ascending: true);

      final pending = await supabase
          .from('call_requests')
          .select('id, user_id, user_name, created_at')
          .eq('doctor_id', doctorId!)
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      setState(() {
        acceptedAppointments = accepted;
        pendingRequests = pending;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error loading data: $e')));
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
      });
    }
  }

  void _showScheduleDialog(Map<String, dynamic> request) {
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();

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
    if (doctorId == null || _selectedDate == null || _selectedTime == null) {
      return;
    }

    try {
      final dateStr = '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr = '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      // Generate unique room name for 8x8 Jitsi
      final roomName = _generateRoomName(request['user_name'].toString());
      
      await supabase.from('appointments').insert({
        'doctor_id': doctorId,
        'user_id': request['user_id'],
        'user_name': request['user_name'],
        'date': dateStr,
        'time': timeStr,
        'meeting_room': roomName,
        'status': 'confirmed',
      });

      await supabase.from('call_requests').delete().eq('id', request['id']);

      await _loadDoctorData();

      _selectedDate = null;
      _selectedTime = null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment scheduled for ${request['user_name']} on $dateStr at ${_selectedTime!.format(context)}'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
      return false;
    }
  }

  bool _isAppointmentExpired(String date, String time) {
    try {
      final now = DateTime.now();
      final appointmentDateTime = DateTime.parse('$date $time');
      
      return now.isAfter(appointmentDateTime.add(const Duration(minutes: 50)));
    } catch (e) {
      return true;
    }
  }

  List<dynamic> get _nonExpiredAppointments {
    return acceptedAppointments.where((appointment) {
      return !_isAppointmentExpired(appointment['date'], appointment['time']);
    }).toList();
  }

  // Function to navigate to Meeting Screen with 8x8 Jitsi
  void _navigateToMeetingScreen(String patientName, String meetingRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingScreen(
          patientName: patientName,
          meetingRoom: meetingRoom,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nonExpiredAppointments = _nonExpiredAppointments;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.teal,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Accepted Appointments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (nonExpiredAppointments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No upcoming appointments',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  else
                    ...nonExpiredAppointments.map((appointment) {
                      final isReady = _isMeetingTimeReady(
                        appointment['date'], 
                        appointment['time']
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
                              Text('Date: ${appointment['date']}'),
                              Text('Time: ${appointment['time']}'),
                              if (isReady)
                                const Text(
                                  'Meeting ready to start',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                onPressed: isReady 
                                    ? () => _navigateToMeetingScreen(
                                      appointment['user_name'] ?? 'Patient',
                                      appointment['meeting_room'] ?? _generateRoomName(appointment['user_name'] ?? 'default'),
                                    )
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isReady ? Colors.green : Colors.grey,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Start Meeting'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  const Text(
                    'Pending Appointments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (pendingRequests.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'No pending appointments',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  else
                    ...pendingRequests.map((request) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              request['user_name'] ?? 'Unknown Patient',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                                'Requested: ${DateTime.parse(request['created_at']).toLocal()}'),
                            trailing: ElevatedButton(
                              onPressed: () => _showScheduleDialog(request),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Schedule'),
                            ),
                          ),
                        )),
                ],
              ),
            ),
    );
  }
}

// New MeetingScreen widget for 8x8 Jitsi integration
class MeetingScreen extends StatefulWidget {
  final String patientName;
  final String meetingRoom;

  const MeetingScreen({
    Key? key,
    required this.patientName,
    required this.meetingRoom,
  }) : super(key: key);

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString(_getJitsiHTML(widget.meetingRoom));
  }

  String _getJitsiHTML(String roomName) {
    return '''
<!DOCTYPE html>
<html>
  <head>
    <script src='https://8x8.vc/vpaas-magic-cookie-c2abd8ebf09446c590d90592e049cd9f/external_api.js' async></script>
    <style>html, body, #jaas-container { height: 100%; margin: 0; padding: 0; }</style>
    <script type="text/javascript">
      window.onload = () => {
        const api = new JitsiMeetExternalAPI("8x8.vc", {
          roomName: "vpaas-magic-cookie-c2abd8ebf09446c590d90592e049cd9f/$roomName",
          parentNode: document.querySelector('#jaas-container'),
          width: "100%",
          height: "100%",
          configOverwrite: {
            prejoinPageEnabled: false,
            startWithAudioMuted: true,
            startWithVideoMuted: false,
            disableModeratorIndicator: false,
            startScreenSharing: false,
            enableEmailInStats: false
          },
          interfaceConfigOverwrite: {
            TOOLBAR_BUTTONS: [
              'microphone', 'camera', 'closedcaptions', 'desktop', 'fullscreen',
              'fodeviceselection', 'hangup', 'profile', 'chat', 'recording',
              'livestreaming', 'etherpad', 'sharedvideo', 'settings', 'raisehand',
              'videoquality', 'filmstrip', 'invite', 'feedback', 'stats', 'shortcuts',
              'tileview', 'videobackgroundblur', 'download', 'help', 'mute-everyone',
              'mute-video-everyone', 'security'
            ],
            SETTINGS_SECTIONS: ['devices', 'language', 'moderator', 'profile', 'calendar'],
            SHOW_JITSI_WATERMARK: false,
            SHOW_WATERMARK_FOR_GUESTS: false,
            DEFAULT_BACKGROUND: '#474747',
            OPTIMAL_BROWSERS: ['chrome', 'chromium', 'firefox', 'nwjs', 'electron', 'safari'],
            BRAND_WATERMARK_LINK: '',
          },
          userInfo: {
            displayName: 'Doctor',
            email: ''
          }
        });
        
        api.addEventListener('videoConferenceJoined', () => {
          console.log('Doctor joined the meeting');
        });
        
        api.addEventListener('videoConferenceLeft', () => {
          console.log('Doctor left the meeting');
          // You can send a message back to Flutter here if needed
        });
        
        api.addEventListener('participantJoined', (participant) => {
          console.log('Participant joined:', participant);
        });
      }
    </script>
  </head>
  <body>
    <div id="jaas-container" style="height: 100vh; width: 100vw;" />
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meeting with ${widget.patientName}'),
        backgroundColor: Colors.teal,
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}