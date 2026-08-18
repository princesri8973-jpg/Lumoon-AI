import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/voice_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final voiceService = VoiceService();
  await voiceService.initialize();

  runApp(LumoonApp(voiceService: voiceService));
}

class LumoonApp extends StatelessWidget {
  final VoiceService voiceService;

  const LumoonApp({
    super.key,
    required this.voiceService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Lumoon",
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      home: HomeScreen(voiceService: voiceService),
    );
  }
}