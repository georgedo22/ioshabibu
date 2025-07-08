//machines class

class Machines {
  final String MachineName;
  final String DriverName;
  final String Status;

  Machines({
    required this.MachineName,
    required this.DriverName,
    required this.Status,
  });

  factory Machines.fromJson(Map<String, dynamic> json) {
    return Machines(
      MachineName: json['MachineName'],
      DriverName: json['DriverName'],
      Status: json['Status'],
    );
  }
}
