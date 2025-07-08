class Project {
  final String name;
  final List<String> engineers;
  final String createdAt;
  final String createdBy;

  Project({
    required this.name,
    required this.engineers,
    required this.createdAt,
    required this.createdBy,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      name: json['name'],
      engineers: List<String>.from(json['engineers']),
      createdAt: json['created_at'],
      createdBy: json['created_by'],
    );
  }
}
