
class InverterSimulator {
  double temperature = 31.0;
  double systemVoltage = 24.6;

  void updateInverter({
    required double totalLoadWatts,
    required int timeIndex,
    double ambientTemp = 30.0,
  }) {
    double baseVolt = (timeIndex == 2) ? 23.8 : 24.6;
    double drop = (totalLoadWatts / 3500.0) * 1.8;
    systemVoltage = double.parse((baseVolt - drop).clamp(20.0, 29.0).toStringAsFixed(1));

    double targetTemp = ambientTemp + ((totalLoadWatts / 1000.0) * 2.5);
    temperature += (targetTemp - temperature) * 0.1;
    temperature = double.parse(temperature.toStringAsFixed(1));
  }

  bool isOverheated() => temperature > 45.0;

  bool isLowVoltage() => systemVoltage < 21.5;
}