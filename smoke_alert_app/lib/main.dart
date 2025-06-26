import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:telephony/telephony.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SmokeAlertApp());
}

class SmokeAlertApp extends StatelessWidget {
  const SmokeAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smoke Alert',
      home: SmokeAlertHomePage(),
    );
  }
}

class SmokeAlertHomePage extends StatefulWidget {
  const SmokeAlertHomePage({super.key});

  @override
  _SmokeAlertHomePageState createState() => _SmokeAlertHomePageState();
}

class _SmokeAlertHomePageState extends State<SmokeAlertHomePage> {
  final databaseRef = FirebaseDatabase.instance.ref();
  final Telephony telephony = Telephony.instance;
  String alertStatus = "Waiting...";
  bool smsSent = false;

  @override
  void initState() {
    super.initState();
    listenToFirebase();
  }

  void listenToFirebase() {
    databaseRef.child("alert").onValue.listen((event) {
      final data = event.snapshot.value?.toString() ?? "Unknown";
      setState(() {
        alertStatus = data;
      });

      if (data == "Gas Still Present" && !smsSent) {
        sendSmsAlert();
      }else if(data == "Smoke/Gas Detected"){
        smsSent = false;
      } 
      else if (data == "Clear") {
        smsSent = false; // Reset SMS trigger
      }
    });
  }

  Future<void> sendSmsAlert() async {
    bool granted = await telephony.requestPhoneAndSmsPermissions ?? false;

    if (granted) {
      await telephony.sendSms(
        to: "09150526494", // ← Replace with your number
        message: "⚠️ Smoke/Gas has been detected for 1 minute!",
      );
      smsSent = true;
    } else {
      print("❌ SMS permission not granted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smoke Alert")),
      body: Center(
        child: Text(
          "Status: $alertStatus",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}