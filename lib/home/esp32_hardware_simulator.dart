
class Esp32HardwareSimulator {
  bool isConnected = true;
  int wifiRssi = -55;
  DateTime lastSyncTime = DateTime.now();
  int errorCount = 0;

  void pingAndUpdate() {
    lastSyncTime = DateTime.now();

    isConnected = true;

    wifiRssi = -55 + (DateTime.now().second % 3);
  }

  String getSignalDescription() {
    if (wifiRssi >= -65) return 'ممتازة ($wifiRssi dBm)';
    if (wifiRssi >= -75) return 'متوسطة ($wifiRssi dBm)';
    return 'ضعيفة ($wifiRssi dBm)';
  }

  String getFormattedLastSync() {
    return '${lastSyncTime.hour.toString().padLeft(2, '0')}:${lastSyncTime.minute.toString().padLeft(2, '0')}:${lastSyncTime.second.toString().padLeft(2, '0')}';
  }
}
