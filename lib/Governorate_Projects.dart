class Governorate_Projects {
  final int project_id;
  final String project_name;
  final int governorate_id;
  final String supervisor_name;

  Governorate_Projects({
    required this.project_id,
    required this.project_name,
    required this.governorate_id,
    required this.supervisor_name,
  });

  factory Governorate_Projects.fromJson(Map<String, dynamic> json) {
    return Governorate_Projects(
      project_id: json['project_id'] ?? 0,
      project_name: json['project_name'] ?? '',
      governorate_id: json['governorate_id'] ?? 0,
      supervisor_name: json['supervisor_name'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Governorate_Projects(project_id: $project_id, project_name: $project_name, supervisor_name: $supervisor_name)';
  }
}
