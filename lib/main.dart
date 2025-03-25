import 'package:fasum/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fasum/screens/sign_in_screen.dart';
import 'package:fasum/screens/sign_up_screen.dart';
import 'package:fasum/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Realtime Database - without persistence for now
  // FirebaseDatabase.instance.setPersistenceEnabled(true);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fasum App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/signin': (context) => const SignInScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
      builder: (context, child) {
        return SafeArea(
          child: child ?? const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    try {
      // Add a small delay to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Debug print to check auth state
      final currentUser = _auth.currentUser;
      print('Current user: ${currentUser?.uid ?? "None"}');
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error in AuthWrapper: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error checking user: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Error initializing app:',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _checkCurrentUser();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Check if user is signed in
    final User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      // User is signed in, navigate to home
      return const HomeScreen();
    } else {
      // User is not signed in, navigate to sign in
      return const SignInScreen();
    }
  }
}

// Error handler wrapper for the app
class AppErrorHandler extends StatelessWidget {
  final Widget child;
  
  const AppErrorHandler({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      print('Flutter error caught: ${details.exception}');
      FlutterError.presentError(details);
    };
    
    // Set custom error widget builder
    ErrorWidget.builder = (FlutterErrorDetails details) {
      print('Building error widget for: ${details.exception}');
      return Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'An error occurred',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  details.exception.toString(),
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    };
    
    return child;
  }
}
