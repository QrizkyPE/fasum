import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _userRef = FirebaseDatabase.instance.ref('users');
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Disabled for troubleshooting
    // FirebaseDatabase.instance.setPersistenceEnabled(true);
    print('HomeScreen initialized - loading user data');
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final User? currentUser = _auth.currentUser;
      print('Current user in HomeScreen: ${currentUser?.uid ?? "None"}');
      
      if (currentUser == null) {
        // Not logged in, navigate to sign-in screen
        print('No user logged in, navigating to sign-in screen');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/signin');
        }
        return;
      }

      print('Fetching user data for: ${currentUser.uid}');
      // Get user data from database
      final snapshot = await _userRef.child(currentUser.uid).get();
      
      if (snapshot.exists) {
        print('User data retrieved successfully');
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      } else {
        print('User data not found in database');
        setState(() {
          _errorMessage = 'User data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _errorMessage = 'Error loading user data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/signin');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUserData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildUserProfile(),
    );
  }

  Widget _buildUserProfile() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User profile header
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  _userData?['name'] ?? 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _userData?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                const Divider(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // User info section
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Created date
          if (_userData?['created_at'] != null)
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Account Created'),
              subtitle: Text(
                DateTime.fromMillisecondsSinceEpoch(
                        _userData!['created_at'] as int)
                    .toString(),
              ),
            ),
          
          // Last login
          if (_userData?['last_login'] != null)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Last Login'),
              subtitle: Text(
                DateTime.fromMillisecondsSinceEpoch(
                        _userData!['last_login'] as int)
                    .toString(),
              ),
            ),
          
          const Divider(),
          const SizedBox(height: 16),
          
          // Actions section
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                // Update user profile action
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }
}
