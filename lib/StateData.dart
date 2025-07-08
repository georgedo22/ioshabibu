import 'package:habibuios/Project.dart';


class StateData {
  final String state;
  final List<Project> projects;

  StateData({required this.state, required this.projects});

  factory StateData.fromJson(Map<String, dynamic> json) {
    var projectsJson = json['projects'] as List<dynamic>;
    List<Project> projects = projectsJson.map((e) => Project.fromJson(e)).toList();
    return StateData(state: json['state'], projects: projects);
  }
}
