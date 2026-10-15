class ApplianceModel {
  final String id;
  final String name;
  final int wattage;
  final String impact;
  bool isOn;

  ApplianceModel({
    required this.id,
    required this.name,
    required this.wattage,
    required this.impact,
    this.isOn = false,
  });
}
