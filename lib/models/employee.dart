class Employee {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String employeeId;
  
  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.employeeId,
  });
  
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'] ?? '',
      employeeId: json['employee_id'],
    );
  }
}