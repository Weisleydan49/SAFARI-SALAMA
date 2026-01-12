import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _user;
  bool _isLoading = true;
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('auth_token');

      if (userId == null || token == null) {
        setState(() {
          _error = 'User not authenticated';
          _isLoading = false;
        });
        return;
      }

      final userData = await ApiService.getUserProfile(
        userId: userId,
        token: token,
      );

      final user = User.fromJson(userData);

      setState(() {
        _user = user;
        _nameController.text = user.name;
        _emailController.text = user.email ?? '';
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      await ApiService.updateUserProfile(
        userId: _user.id,
        name: _nameController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        token: token,
      );

      if (!mounted) return;

      setState(() {
        _user = User(
          id: _user.id,
          phone: _user.phone,
          name: _nameController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          userType: _user.userType,
          profilePhotoUrl: _user.profilePhotoUrl,
          isVerified: _user.isVerified,
          isActive: _user.isActive,
          createdAt: _user.createdAt,
        );
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 48),
                      SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadUserProfile,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Profile Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade200,
                        ),
                        child: _user.profilePhotoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  _user.profilePhotoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.person,
                                        size: 50, color: Colors.white);
                                  },
                                ),
                              )
                            : Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      SizedBox(height: 24),

                      // User Info Card
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Phone (read-only)
                              _buildInfoField(
                                label: 'Phone',
                                value: _user.phone,
                                readOnly: true,
                              ),
                              SizedBox(height: 20),

                              // User Type
                              _buildInfoField(
                                label: 'Account Type',
                                value: _user.userType
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                readOnly: true,
                              ),
                              SizedBox(height: 20),

                              // Verification Status
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Verified Account'),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: _user.isVerified
                                          ? Colors.green.shade100
                                          : Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _user.isVerified
                                          ? 'Verified'
                                          : 'Not Verified',
                                      style: TextStyle(
                                        color: _user.isVerified
                                            ? Colors.green
                                            : Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Editable Fields
                      if (_isEditing)
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email (Optional)',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: Icon(Icons.check),
                                        label: Text('Save'),
                                        onPressed: _updateProfile,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: Icon(Icons.close),
                                        label: Text('Cancel'),
                                        onPressed: () {
                                          setState(() => _isEditing = false);
                                          _nameController.text = _user.name;
                                          _emailController.text =
                                              _user.email ?? '';
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 24),

                      // Logout Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.logout),
                          label: Text('Logout'),
                          onPressed: _logout,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required String value,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
