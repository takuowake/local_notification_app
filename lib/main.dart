import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  Timer? _minuteTimer;
  bool _minuteNotifications = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _configureLocalTimeZone();
    await _initializeNotification();
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    final String? timeZoneName = await FlutterNativeTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName!));
  }

  Future<void> _initializeNotification() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('ic_notification');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotificationNow() async {
    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
        channelId: 'instant_channel_id',
        channelName: 'Instant Channel',
        channelDescription: 'Instant notifications',
        importance: Importance.max,
        priority: Priority.high);
    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.show(
        0, 'Instant Notification', 'This is an instant notification',
        notificationDetails);
  }

  Future<void> _scheduleNotificationAt(DateTime scheduledTime) async {
    final tz.TZDateTime tzScheduledTime =
    tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails(
        channelId: 'scheduled_channel_id',
        channelName: 'Scheduled Channel',
        channelDescription: 'Scheduled notifications',
        importance: Importance.max,
        priority: Priority.high);

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidNotificationDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
        1,
        'Scheduled Notification',
        'This is a scheduled notification',
        tzScheduledTime,
        notificationDetails,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);
  }

  Future<void> _cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  void _startMinuteNotifications() {
    _minuteTimer = Timer.periodic(Duration(minutes: 1), (Timer timer) async {
      if (!_minuteNotifications) {
        timer.cancel();
        return;
      }
      await _showNotificationNow();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Notifications'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _showNotificationNow();
              },
              child: const Text('Show Notification Now'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _scheduleNotificationAt(
                    DateTime.now().add(Duration(seconds: 10)));
              },
              child: const Text('Schedule Notification in 10 seconds'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _cancelAllNotifications();
              },
              child: const Text('Cancel All Notifications'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Enable 1-minute Notifications'),
                Radio<bool>(
                  value: true,
                  groupValue: _minuteNotifications,
                  onChanged: (bool? value) {
                    setState(() {
                      _minuteNotifications = value!;
                      _startMinuteNotifications();
                    });
                  },
                ),
                const Text('Disable'),
                Radio<bool>(
                  value: false,
                  groupValue: _minuteNotifications,
                  onChanged: (bool? value) {
                    setState(() {
                      _minuteNotifications = value!;
                    });
                  },
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () async {
                final List<PendingNotificationRequest> pendingNotifications =
                await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Pending Notifications'),
                      content: Text(
                          'There are ${pendingNotifications.length} pending notifications.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('OK'),
                        )
                      ],
                    );
                  },
                );
              },
              child: const Text('Check Pending Notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
