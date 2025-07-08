import 'package:flutter/material.dart';
import 'package:habibuios/test/ProjectDetailsPage.dart';
import 'Project.dart';

class ProjectInformationScreen extends StatelessWidget {
  final String stateName;
  final List<Project> projects;

  ProjectInformationScreen({required this.stateName, required this.projects});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${stateName} Projects',),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: projects.length,
        itemBuilder: (context, index) {
          final project = projects[index];
          return InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder:(context)=>ProjectDetailsPage(project: project,)));
            },
            child: Card(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 3,
              child: ListTile(
                title: Text(project.name),
                subtitle: Text("CreatedBy :  ${project.createdBy}"),
                trailing: Text(
                  project.createdAt.split("T").first,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
