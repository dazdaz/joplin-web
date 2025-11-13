import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service.dart';
import 'screens.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => JoplinService())],
      child: const JoplinShellApp(),
    ),
  );
}

class JoplinShellApp extends StatelessWidget {
  const JoplinShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Joplin Web Shell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF106BA3),
          surface: Colors.white,
        ),
      ),
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<JoplinService>();
    
    if (service.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Row(
        children: [
          // 1. Sidebar
          Container(
            width: 260,
            color: const Color(0xFF2D3136),
            child: const Sidebar(),
          ),
          // 2. Note List
          Container(
            width: 280,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey, width: 0.5)),
            ),
            child: const NoteList(),
          ),
          // 3. Editor/Viewer
          const Expanded(
            child: EditorPane(),
          ),
        ],
      ),
    );
  }
}
