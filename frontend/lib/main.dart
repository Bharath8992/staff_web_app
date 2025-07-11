import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MaterialApp(home: StaffListPage(), debugShowCheckedModeBanner: false));

class Staff {
  final int? id;
  final String firstName, lastName, gender, dob, email, jobTitle, department, dutyStation;

  Staff({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.dob,
    required this.email,
    required this.jobTitle,
    required this.department,
    required this.dutyStation,
  });

  factory Staff.fromJson(Map<String, dynamic> json) => Staff(
        id: json['id'],
        firstName: json['first_name'],
        lastName: json['last_name'],
        gender: json['gender'],
        dob: json['dob'],
        email: json['email'],
        jobTitle: json['job_title'],
        department: json['department'],
        dutyStation: json['duty_station'],
      );

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        'dob': dob,
        'email': email,
        'job_title': jobTitle,
        'department': department,
        'duty_station': dutyStation,
      };
}

class StaffListPage extends StatefulWidget {
  @override
  _StaffListPageState createState() => _StaffListPageState();
}

class _StaffListPageState extends State<StaffListPage> {
  List<Staff> staffList = [];
  int currentPage = 1;
  final int pageSize = 10;
  String sortBy = "first_name";
  String sortOrder = "asc";
  String searchQuery = "";

  TextEditingController searchController = TextEditingController();

  Future<void> fetchStaffs() async {
    final uri = Uri.parse(
        'http://127.0.0.1:8000/staff?page=$currentPage&page_size=$pageSize&search=$searchQuery&sort_by=$sortBy&sort_order=$sortOrder');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      setState(() {
        staffList = data.map((json) => Staff.fromJson(json)).toList();
      });
    } else {
      setState(() {
        staffList = [];
      });
    }
  }

  Future<void> deleteStaff(int id) async {
    await http.delete(Uri.parse('http://127.0.0.1:8000/staff/$id'));
    fetchStaffs();
  }

  Future<void> createStaff(Staff staff) async {
    await http.post(
      Uri.parse('http://127.0.0.1:8000/staff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(staff.toJson()),
    );
    fetchStaffs();
  }

  Future<void> updateStaff(int id, Staff staff) async {
    await http.put(
      Uri.parse('http://127.0.0.1:8000/staff/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(staff.toJson()),
    );
    fetchStaffs();
  }

  @override
  void initState() {
    super.initState();
    fetchStaffs();
  }

  void nextPage() {
    setState(() {
      currentPage++;
    });
    fetchStaffs();
  }

  void prevPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
      fetchStaffs();
    }
  }

  void search() {
    setState(() {
      searchQuery = searchController.text;
      currentPage = 1;
    });
    fetchStaffs();
  }

  void sort(String field) {
    setState(() {
      if (sortBy == field) {
        sortOrder = sortOrder == "asc" ? "desc" : "asc";
      } else {
        sortBy = field;
        sortOrder = "asc";
      }
    });
    fetchStaffs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff List (Page $currentPage)'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add Staff',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => StaffFormDialog(
                onSubmit: (staff) => createStaff(staff),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Search...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => search(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: search,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                sortAscending: sortOrder == "asc",
                sortColumnIndex: sortBy == "first_name"
                    ? 0
                    : sortBy == "last_name"
                        ? 1
                        : sortBy == "gender"
                            ? 2
                            : null,
                columns: [
                  DataColumn(
                    label: Text('First Name'),
                    onSort: (i, asc) => sort("first_name"),
                  ),
                  DataColumn(
                    label: Text('Last Name'),
                    onSort: (i, asc) => sort("last_name"),
                  ),
                  DataColumn(
                    label: Text('Gender'),
                    onSort: (i, asc) => sort("gender"),
                  ),
                  DataColumn(label: Text('DOB')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Job Title')),
                  DataColumn(label: Text('Department')),
                  DataColumn(label: Text('Duty Station')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: staffList.map((staff) {
                  return DataRow(cells: [
                    DataCell(Text(staff.firstName)),
                    DataCell(Text(staff.lastName)),
                    DataCell(Text(staff.gender)),
                    DataCell(Text(staff.dob)),
                    DataCell(Text(staff.email)),
                    DataCell(Text(staff.jobTitle)),
                    DataCell(Text(staff.department)),
                    DataCell(Text(staff.dutyStation)),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => StaffFormDialog(
                              staff: staff,
                              onSubmit: (updated) => updateStaff(staff.id!, updated),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteStaff(staff.id!),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: prevPage, child: Text("Previous")),
                SizedBox(width: 16),
                Text('Page $currentPage'),
                SizedBox(width: 16),
                ElevatedButton(onPressed: nextPage, child: Text("Next")),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StaffFormDialog extends StatefulWidget {
  final Staff? staff;
  final Function(Staff) onSubmit;

  StaffFormDialog({this.staff, required this.onSubmit});

  @override
  _StaffFormDialogState createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController genderController;
  late TextEditingController dobController;
  late TextEditingController emailController;
  late TextEditingController jobTitleController;
  late TextEditingController departmentController;
  late TextEditingController dutyStationController;

  @override
  void initState() {
    super.initState();
    final s = widget.staff;
    firstNameController = TextEditingController(text: s?.firstName ?? '');
    lastNameController = TextEditingController(text: s?.lastName ?? '');
    genderController = TextEditingController(text: s?.gender ?? '');
    dobController = TextEditingController(text: s?.dob ?? '');
    emailController = TextEditingController(text: s?.email ?? '');
    jobTitleController = TextEditingController(text: s?.jobTitle ?? '');
    departmentController = TextEditingController(text: s?.department ?? '');
    dutyStationController = TextEditingController(text: s?.dutyStation ?? '');
  }

  void submit() {
    if (_formKey.currentState!.validate()) {
      final newStaff = Staff(
        id: widget.staff?.id,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        gender: genderController.text,
        dob: dobController.text,
        email: emailController.text,
        jobTitle: jobTitleController.text,
        department: departmentController.text,
        dutyStation: dutyStationController.text,
      );
      widget.onSubmit(newStaff);
      Navigator.pop(context);
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: OutlineInputBorder()),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildGenderDropdown(TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        value: controller.text.isNotEmpty ? controller.text : null,
        items: ['Male', 'Female', 'Other'].map((gender) {
          return DropdownMenuItem<String>(
            value: gender,
            child: Text(gender),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            controller.text = value ?? '';
          });
        },
        decoration: InputDecoration(
          labelText: 'Gender',
          border: OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  Widget _buildDatePicker(TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.tryParse(controller.text) ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            controller.text = picked.toIso8601String().split('T').first;
          }
        },
        decoration: InputDecoration(
          labelText: 'DOB',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.staff != null ? 'Edit Staff' : 'Add Staff'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(firstNameController, 'First Name'),
              _buildTextField(lastNameController, 'Last Name'),
              _buildGenderDropdown(genderController),
              _buildDatePicker(dobController),
              _buildTextField(emailController, 'Email'),
              _buildTextField(jobTitleController, 'Job Title'),
              _buildTextField(departmentController, 'Department'),
              _buildTextField(dutyStationController, 'Duty Station'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
        ElevatedButton(onPressed: submit, child: Text('Submit')),
      ],
    );
  }
}
