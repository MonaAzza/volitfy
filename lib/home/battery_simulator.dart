
class BatterySimulator {
  final double capacityWh = 3000.0;
  double currentStoredWh = 2160.0;
  double batteryPercentage = 72.0;
  double healthPercentage = 99.0;

  final double chargeEfficiency = 0.92;
  final double dischargeEfficiency = 0.98;

  void updateBattery(double netWatts, double deltaTimeSeconds) {
    double energyChangeWh = 0.0;

    if (netWatts > 0) {
      energyChangeWh = (netWatts * chargeEfficiency) * (deltaTimeSeconds / 3600.0);
    } else {
      energyChangeWh = (netWatts / dischargeEfficiency) * (deltaTimeSeconds / 3600.0);
    }

    currentStoredWh = (currentStoredWh + energyChangeWh).clamp(0.0, capacityWh);
    batteryPercentage = double.parse(((currentStoredWh / capacityWh) * 100.0).toStringAsFixed(1));
  }

  void setTargetPercentageSmoothly(double targetPercentage) {
    double targetWh = capacityWh * (targetPercentage / 100.0);
    currentStoredWh += (targetWh - currentStoredWh) * 0.05;
    batteryPercentage = double.parse(((currentStoredWh / capacityWh) * 100.0).toStringAsFixed(1));
  }

  String getRuntimeText(double netWatts, double totalActiveLoad) {
    if (netWatts >= 0) {
      if (netWatts == 0) return 'البطارية مستقرة وممتلئة';
      double hoursToFull = (capacityWh - currentStoredWh) / (netWatts * chargeEfficiency);
      int minutes = (hoursToFull * 60).toInt();
      int h = minutes ~/ 60;
      int m = minutes % 60;
      return 'البطارية تشحن خلال (${h > 0 ? '$hس ' : ''}$mد)';
    } else {
      double drain = netWatts.abs();
      if (drain == 0) drain = 50;
      double hoursRemaining = currentStoredWh / drain;
      int minutes = (hoursRemaining * 60).toInt();
      int h = minutes ~/ 60;
      int m = minutes % 60;
      return 'تنفذ البطارية خلال ($hس $mد)';
    }
  }
}