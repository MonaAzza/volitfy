
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../screens/chat_screen.dart';

class ApplianceModel {
  final String id;
  final String name;
  final double wattage;
  final String impact;
  final IconData icon;
  bool isOn;

  ApplianceModel({
    required this.id,
    required this.name,
    required this.wattage,
    required this.impact,
    required this.icon,
    this.isOn = true,
  });
}

class HomeScreen extends StatefulWidget {
  final String userEmail;

  const HomeScreen({super.key, required this.userEmail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _liveTimer;
  int _selectedTimeIndex = 1; // 1: 12:00 م (الافتراضية)

  // القيم الحالية للنظام
  double _currentSolarGenerationWatts = 3200.0;
  double _currentBatteryPercentage = 72.0;
  double _currentInverterTemp = 31.0;
  double _currentSystemVoltage = 24.6;

  // القيم المستهدفة للانتقال التدريجي
  double _targetSolarGenerationWatts = 3200.0;

  final double _batteryCapacityWh = 3000.0;

  // حالة الطقس المضافة
  bool _isCloudyWeather = false;
  String _weatherDescription = 'مشمس وواضح';

  String get _userName {
    if (widget.userEmail.isEmpty) return 'أحمد';
    final parts = widget.userEmail.split('@');
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      String name = parts[0];
      return name == 'ahmed' ? 'أحمد' : (name[0].toUpperCase() + name.substring(1));
    }
    return 'أحمد';
  }

  String get _dynamicWelcomeMessage {
    if (_selectedTimeIndex == 0) return 'صباح الخير والنشاط، $_userName!';
    if (_selectedTimeIndex == 1) return 'أهلاً بك يا $_userName، طابت أوقاتك.';
    return 'مساء الخير يا $_userName، وقت الراحة الآن.';
  }

  final List<ApplianceModel> _appliances = [
    ApplianceModel(id: '1', name: 'الثلاجة (150 واط)', wattage: 150, impact: 'تأثير خفيف', icon: Icons.kitchen, isOn: true),
    ApplianceModel(id: '2', name: 'الإنارة (40 واط)', wattage: 40, impact: 'تأثير خفيف جداً', icon: Icons.lightbulb_outline, isOn: true),
    ApplianceModel(id: '3', name: 'الغسالة (500 واط)', wattage: 500, impact: 'حمل متوسط', icon: Icons.local_laundry_service, isOn: true),
    ApplianceModel(id: '4', name: 'الغاز (100 واط)', wattage: 100, impact: 'تأثير خفيف', icon: Icons.local_fire_department, isOn: true),
    ApplianceModel(id: '5', name: 'التكييف (1000 واط)', wattage: 1000, impact: 'حمل مرتفع', icon: Icons.ac_unit, isOn: false),
    ApplianceModel(id: '6', name: 'السخان (2000 واط)', wattage: 2000, impact: 'حمل مرتفع', icon: Icons.radar_rounded, isOn: false),
  ];

  @override
  void initState() {
    super.initState();
    _updateTargetsForTimeIndex(_selectedTimeIndex, instant: true);

    _liveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        double totalLoad = _totalActiveLoad;

        double effectiveTargetSolar = _targetSolarGenerationWatts;
        if (_isCloudyWeather && effectiveTargetSolar > 0) {
          effectiveTargetSolar *= 0.5;
        }

        double solarDiff = effectiveTargetSolar - _currentSolarGenerationWatts;
        _currentSolarGenerationWatts += solarDiff * 0.1;
        if (_currentSolarGenerationWatts < 5) _currentSolarGenerationWatts = 0;

        double netPower = _currentSolarGenerationWatts - totalLoad;
        double percentageDelta = (netPower / _batteryCapacityWh) * 1.5;
        _currentBatteryPercentage += percentageDelta;

        _currentBatteryPercentage = _currentBatteryPercentage.clamp(10.0, 100.0);

        double baseVolt = (_selectedTimeIndex == 2) ? 23.8 : 24.6;
        double voltDrop = (totalLoad / 3500.0) * 1.5;
        double targetVolt = baseVolt - voltDrop;
        _currentSystemVoltage += (targetVolt - _currentSystemVoltage) * 0.2;

        double ambientTemp = (_selectedTimeIndex == 1) ? 30.0 : 24.0;
        double targetTemp = ambientTemp + ((totalLoad / 1000.0) * 2.5);
        _currentInverterTemp += (targetTemp - _currentInverterTemp) * 0.1;

        _currentSolarGenerationWatts = double.parse(_currentSolarGenerationWatts.toStringAsFixed(1));
        _currentBatteryPercentage = double.parse(_currentBatteryPercentage.toStringAsFixed(1));
        _currentInverterTemp = double.parse(_currentInverterTemp.toStringAsFixed(1));
        _currentSystemVoltage = double.parse(_currentSystemVoltage.toStringAsFixed(1));
      });
    });
  }

  void _updateTargetsForTimeIndex(int index, {bool instant = false}) {
    _selectedTimeIndex = index;
    if (index == 0) {
      _targetSolarGenerationWatts = 1600.0;
      if (instant) _currentBatteryPercentage = 65.0;
      _weatherDescription = 'صباح مشمس لطيف';
    } else if (index == 1) {
      _targetSolarGenerationWatts = 3200.0;
      if (instant) _currentBatteryPercentage = 72.0;
      _weatherDescription = _isCloudyWeather ? 'طقس غائم جزئياً' : 'مشمس وواضح';
    } else {
      _targetSolarGenerationWatts = 0.0;
      if (instant) _currentBatteryPercentage = 45.0;
      _weatherDescription = 'أجواء صافية ليلاً';
    }
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  double get _totalActiveLoad {
    double baseIdleLoad = 30.0;
    return _appliances
        .where((app) => app.isOn)
        .fold(baseIdleLoad, (sum, item) => sum + item.wattage);
  }

  double get _netPower => _currentSolarGenerationWatts - _totalActiveLoad;

  bool get _isSystemInDanger {
    if (_currentBatteryPercentage < 15.0) return true;
    if (_currentSystemVoltage < 21.0) return true;
    if (_currentInverterTemp > 45.0) return true;
    if (_netPower < -2000.0) return true;
    return false;
  }

  String get _systemStatusMessage {
    if (_isSystemInDanger) {
      if (_currentBatteryPercentage < 15.0) return 'خطر: البطارية شبه فارغة، يرجى إطفاء الأحمال!';
      if (_currentSystemVoltage < 21.0) return 'تنبيه: حمل زائد يفوق قدرة نظام التحويل!';
      if (_currentInverterTemp > 45.0) return 'تحذير: حرارة الإنفرتر تخطت الحد الآمن!';
      return 'تنبيه: عجز كبير في الطاقة، النظام مهدد!';
    }

    if (_netPower < 0) {
      return 'النظام يعتمد جزئياً على البطارية (استهلاك معتدل).';
    } else if (_currentSolarGenerationWatts > 0) {
      return 'التوليد الشمسي يغطي الأحمال وتشحن البطارية بكفاءة.';
    }

    return 'النظام يعمل بكفاءة وأمان تام.';
  }

  String get _batteryRuntimeText {
    if (_netPower >= 0) {
      if (_netPower == 0) return 'البطارية مستقرة.';
      double whToFull = _batteryCapacityWh * (1 - (_currentBatteryPercentage / 100));
      double hours = whToFull / (_netPower * 0.9);
      int totalMinutes = (hours * 60).toInt();
      return 'تشحن بالكامل خلال ${totalMinutes ~/ 60}س ${totalMinutes % 60}د';
    } else {
      double whAvailable = _batteryCapacityWh * (_currentBatteryPercentage / 100);
      double hours = whAvailable / _netPower.abs();
      int totalMinutes = (hours * 60).toInt();
      return 'تنفذ البطارية خلال ${totalMinutes ~/ 60}س ${totalMinutes % 60}د';
    }
  }

  void _onTimeTabChanged(int index) {
    setState(() {
      _updateTargetsForTimeIndex(index);
    });
  }

  void _stopAllLoads() {
    setState(() {
      for (var app in _appliances) {
        app.isOn = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إيقاف جميع الأحمال بنجاح!'), backgroundColor: Colors.orange),
    );
  }

  void _toggleWeatherCondition() {
    setState(() {
      _isCloudyWeather = !_isCloudyWeather;
      _weatherDescription = _isCloudyWeather ? 'طقس غائم ومحمل بالسحب' : 'مشمس وواضح تماماً';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم تحديث الطقس: $_weatherDescription'), backgroundColor: Colors.blue),
    );
  }

  void _navigateToChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          userName: _userName,
          batteryPercentage: _currentBatteryPercentage,
          solarGenerationWatts: _currentSolarGenerationWatts,
          currentLoadWatts: _totalActiveLoad,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'images/voltify_logo.png',
                            width: 24.r,
                            height: 24.r,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.wb_sunny_outlined, color: AppColors.primary, size: 20.r),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dynamicWelcomeMessage,
                              style: GoogleFonts.tajawal(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'إليك أداء نظامك الشمسي الآن',
                              style: GoogleFonts.tajawal(
                                fontSize: 11.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F5F7),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: GestureDetector(onTap: () => _onTimeTabChanged(0), child: _buildTimeTab('6:00 ص', Icons.wb_sunny_outlined, _selectedTimeIndex == 0))),
                      Expanded(child: GestureDetector(onTap: () => _onTimeTabChanged(1), child: _buildTimeTab('12:00 م', Icons.solar_power, _selectedTimeIndex == 1))),
                      Expanded(child: GestureDetector(onTap: () => _onTimeTabChanged(2), child: _buildTimeTab('ليلاً', Icons.nightlight_outlined, _selectedTimeIndex == 2))),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: _isSystemInDanger ? Colors.red.shade50 : (_netPower < -1000 ? const Color(0xFFFFF3E0) : const Color(0xFFF1F8F5)),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: _isSystemInDanger ? Colors.red.shade300 : (_netPower < -1000 ? Colors.orange.shade300 : const Color(0xFFC8E6C9)),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30.r,
                        height: 30.r,
                        decoration: BoxDecoration(
                          color: _isSystemInDanger ? Colors.red.shade100 : (_netPower < -1000 ? Colors.orange.shade100 : const Color(0xFF4CAF50)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSystemInDanger ? Icons.priority_high : Icons.check,
                          color: _isSystemInDanger ? Colors.red.shade800 : (_netPower < -1000 ? Colors.orange.shade800 : Colors.white),
                          size: 16.r,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'حالة النظام الحية',
                              style: GoogleFonts.tajawal(
                                fontSize: 10.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              _systemStatusMessage,
                              style: GoogleFonts.tajawal(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: _isSystemInDanger ? Colors.red.shade800 : (_netPower < -1000 ? Colors.orange.shade800 : const Color(0xFF2E7D32)),
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '● متصل  |  تحديث: تلقائي ومباشر',
                              style: GoogleFonts.tajawal(
                                fontSize: 9.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_left, color: _isSystemInDanger ? Colors.red : const Color(0xFF2E7D32), size: 20.r),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFEFEFEF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentBatteryPercentage > 30 ? 'حالة البطارية ممتازة ومستقرة' : 'تحذير: مستوى البطارية منخفض',
                        style: GoogleFonts.tajawal(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: _currentBatteryPercentage > 30 ? const Color(0xFF2E7D32) : Colors.red,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 55.r,
                                height: 55.r,
                                child: CircularProgressIndicator(
                                  value: (_currentBatteryPercentage / 100).clamp(0.0, 1.0),
                                  backgroundColor: Colors.grey.shade100,
                                  color: const Color(0xFF4CAF50),
                                  strokeWidth: 6,
                                ),
                              ),
                              Icon(Icons.battery_charging_full, color: const Color(0xFF4CAF50), size: 22.r),
                            ],
                          ),
                          SizedBox(width: 14.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('نسبة شحن البطارية', style: GoogleFonts.tajawal(fontSize: 10.sp, color: AppColors.textSecondary)),
                                    Text('صحة البطارية', style: GoogleFonts.tajawal(fontSize: 10.sp, color: AppColors.textSecondary)),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${_currentBatteryPercentage.toInt()}%', style: GoogleFonts.tajawal(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                    Text('99%', style: GoogleFonts.tajawal(fontSize: 16.sp, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  _batteryRuntimeText,
                                  style: GoogleFonts.tajawal(fontSize: 9.sp, fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.w,
                        mainAxisSpacing: 8.h,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.4,
                        children: [
                          _buildFigmaStatCard('توليد الألواح', '${_currentSolarGenerationWatts.toInt()} w', Icons.solar_power),
                          _buildFigmaStatCard('جهد النظام', '$_currentSystemVoltage V', Icons.bolt),
                          _buildFigmaStatCard(
                            'شحن البطارية',
                            '${_netPower >= 0 ? '+' : ''}${_netPower.toInt()} w',
                            Icons.battery_charging_full,
                          ),
                          _buildFigmaStatCard('حرارة الإنفرتر', '$_currentInverterTemp°م', Icons.thermostat),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: const Color(0xFFFFE082)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 18.r),
                              SizedBox(width: 6.w),
                              Text(
                                'حالة الطقس والتوصيات',
                                style: GoogleFonts.tajawal(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: _toggleWeatherCondition,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade200,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                _isCloudyWeather ? '☁️ غائم' : '☀️ مشمس',
                                style: GoogleFonts.tajawal(fontSize: 10.sp, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _isCloudyWeather
                            ? 'الطقس حالياً غائم ($_weatherDescription).\nتم تخفيض توليد الألواح بنسبة 50% تلقائياً.'
                            : 'من المتوقع أن يكون الطقس مستقراً.\nالحالة الحالية: $_weatherDescription.',
                        style: GoogleFonts.tajawal(
                          fontSize: 11.sp,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: Colors.amber.shade800, size: 13.r),
                          SizedBox(width: 4.w),
                          Text(
                            _isCloudyWeather ? 'يُفضل إيقاف الأجهزة غير الضرورية الآن.' : 'قلل تشغيل الأجهزة عالية الاستهلاك ظهراً.',
                            style: GoogleFonts.tajawal(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: _navigateToChatScreen,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
                            minimumSize: Size.zero,
                          ),
                          child: Text(
                            'عرض التفاصيل',
                            style: GoogleFonts.tajawal(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),
                Text(
                  'التحكم في الأحمال',
                  style: GoogleFonts.tajawal(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 10.h),

                GridView.builder(
                  itemCount: _appliances.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.w,
                    mainAxisSpacing: 8.h,
                    childAspectRatio: 2.2,
                  ),
                  itemBuilder: (context, index) {
                    final app = _appliances[index];
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: const Color(0xFFEFEFEF)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.r),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F6EE),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(app.icon, color: AppColors.primary, size: 16.r),
                          ),
                          SizedBox(width: 4.w),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  app.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 1.h),
                                Text(
                                  app.impact,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 8.5.sp,
                                    color: app.wattage >= 1000 ? Colors.red : const Color(0xFF4CAF50),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 2.w),

                          Transform.scale(
                            scale: 0.75,
                            child: Switch(
                              value: app.isOn,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  app.isOn = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 16.h),

                SizedBox(
                  width: double.infinity,
                  height: 46.h,
                  child: OutlinedButton.icon(
                    onPressed: _stopAllLoads,
                    icon: const Icon(Icons.power_settings_new, color: Colors.red, size: 18),
                    label: Text(
                      'إيقاف لجميع الأحمال',
                      style: GoogleFonts.tajawal(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _navigateToChatScreen,
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          label: Text(
            'اسأل فورتيفاي',
            style: GoogleFonts.tajawal(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFigmaStatCard(String title, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18.r),
          SizedBox(width: 6.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(fontSize: 9.sp, color: AppColors.textSecondary),
                ),
                SizedBox(height: 1.h),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.tajawal(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeTab(String label, IconData icon, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 15.r,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 11.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.textDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}