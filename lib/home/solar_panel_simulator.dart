
class SolarPanelSimulator {
  double currentGenerationWatts = 0.0;
  bool isCloudy = false;
  double panelCapacityWatts = 3200.0;
  double ambientTemperature = 30.0;

  void updateGeneration(int timeIndex) {
    double solarFactor = 0.0;

    if (timeIndex == 0) {
      solarFactor = 0.5;
    } else if (timeIndex == 1) {
      solarFactor = 1.0;
    } else {
      solarFactor = 0.0;
    }

    double baseGeneration = panelCapacityWatts * solarFactor;

    if (isCloudy && baseGeneration > 0) {
      baseGeneration *= 0.45;
    }
    if (baseGeneration > 0 && ambientTemperature > 25.0) {
      double tempCoefficient = 1.0 - ((ambientTemperature - 25.0) * 0.004);
      baseGeneration *= tempCoefficient.clamp(0.7, 1.0);
    }

    currentGenerationWatts = baseGeneration < 0 ? 0.0 : double.parse(baseGeneration.toStringAsFixed(1));
  }
}