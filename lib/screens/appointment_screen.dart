import 'package:flutter/material.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  final List<Map<String, dynamic>> _appointments = [
    {
      'id': '1',
      'patientName': 'John Doe',
      'patientAge': 32,
      'date': '2024-01-15',
      'time': '10:00 AM',
      'status': 'Confirmed',
      'type': 'Follow-up',
    },
    {
      'id': '2',
      'patientName': 'Jane Smith',
      'patientAge': 28,
      'date': '2024-01-15',
      'time': '2:30 PM',
      'status': 'Pending',
      'type': 'Consultation',
    },
    {
      'id': '3',
      'patientName': 'Robert Johnson',
      'patientAge': 45,
      'date': '2024-01-16',
      'time': '11:15 AM',
      'status': 'Confirmed',
      'type': 'Check-up',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _appointments.isEmpty
          ? const Center(
              child: Text(
                'No appointments scheduled',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        color: Colors.teal,
                        size: 24,
                      ),
                    ),
                    title: Text(
                      appointment['patientName'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Age: ${appointment['patientAge']}'),
                        Text('Date: ${appointment['date']}'),
                        Text('Time: ${appointment['time']}'),
                        Text('Type: ${appointment['type']}'),
                      ],
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment['status']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        appointment['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewAppointment,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _addNewAppointment() {
    // TODO: Implement add new appointment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add new appointment functionality'),
      ),
    );
  }
}