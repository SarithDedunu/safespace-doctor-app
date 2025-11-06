import 'package:flutter/material.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final List<Map<String, dynamic>> _patients = [
    {
      'id': '1',
      'name': 'John Doe',
      'age': 32,
      'gender': 'Male',
      'lastVisit': '2024-01-10',
      'condition': 'Hypertension',
      'phone': '+1-555-0101',
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'age': 28,
      'gender': 'Female',
      'lastVisit': '2024-01-08',
      'condition': 'Diabetes',
      'phone': '+1-555-0102',
    },
    {
      'id': '3',
      'name': 'Robert Johnson',
      'age': 45,
      'gender': 'Male',
      'lastVisit': '2024-01-05',
      'condition': 'Asthma',
      'phone': '+1-555-0103',
    },
    {
      'id': '4',
      'name': 'Sarah Wilson',
      'age': 38,
      'gender': 'Female',
      'lastVisit': '2024-01-03',
      'condition': 'Migraine',
      'phone': '+1-555-0104',
    },
  ];

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
            icon: const Icon(Icons.search),
            onPressed: _searchPatients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
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
            child: _patients.isEmpty
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
                              Text('Age: ${patient['age']} | ${patient['gender']}'),
                              Text('Condition: ${patient['condition']}'),
                              Text('Last Visit: ${patient['lastVisit']}'),
                              Text('Phone: ${patient['phone']}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onPressed: () => _viewPatientDetails(patient),
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

  void _searchPatients() {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Search patients functionality'),
      ),
    );
  }

  void _filterPatients(String query) {
    // TODO: Implement patient filtering
    setState(() {
      // Filter logic would go here
    });
  }

  void _viewPatientDetails(Map<String, dynamic> patient) {
    // TODO: Implement patient details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('View details for ${patient['name']}'),
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
}