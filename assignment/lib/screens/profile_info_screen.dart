import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileInfoScreen extends StatefulWidget {
  const ProfileInfoScreen({super.key});

  @override
  State<ProfileInfoScreen> createState() => _ProfileInfoScreenState();
}

class _ProfileInfoScreenState extends State<ProfileInfoScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('name') ?? '';
      _contactController.text = prefs.getString('phone') ?? '';
      _addressController.text = prefs.getString('address') ?? '';
      _stateController.text = prefs.getString('state') ?? '';
      _districtController.text = prefs.getString('district') ?? '';
      _selectedGender = prefs.getString('gender') ?? 'Male';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Profile Information'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              Text(
                _nameController.text.isNotEmpty ? _nameController.text : 'User',
                style: AppTextStyles.headline1,
              ),

              const SizedBox(height: 24),
              
              // Form Fields
              _buildTextField(
                controller: _nameController,
                label: 'NAME',
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _contactController,
                label: 'CONTACT NO',
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _addressController,
                label: 'ADDRESS',
                enabled: _isEditing,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _stateController,
                label: 'STATE',
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _districtController,
                label: 'DISTRICT',
                enabled: _isEditing,
              ),
              const SizedBox(height: 16),
              
              // Gender Selection
              _buildGenderSelection(),
              const SizedBox(height: 24),
              
              // Action Buttons
              if (_isEditing) ...[
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _cancelEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: Colors.black), // <-- Field value color
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black), // Optional: label color
        hintText: controller.text,
        hintStyle: const TextStyle(color: Colors.black), // <-- Placeholder color
        border: const OutlineInputBorder(),
        filled: !enabled,
        fillColor: enabled ? null : AppColors.background,
      ),
    );
  }

  Widget _buildGenderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GENDER',
          style: AppTextStyles.body2.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.black, 
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  'Male',
                  style: TextStyle(color: Colors.black), // <-- Make option black
                ),
                value: 'Male',
                groupValue: _selectedGender,
                onChanged: _isEditing
                    ? (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      }
                    : null,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  'Female',
                  style: TextStyle(color: Colors.black), // <-- Make option black
                ),
                value: 'Female',
                groupValue: _selectedGender,
                onChanged: _isEditing
                    ? (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      }
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _saveProfile() async {
  if (_formKey.currentState!.validate()) {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', _nameController.text);
    await prefs.setString('phone', _contactController.text);
    await prefs.setString('address', _addressController.text);
    await prefs.setString('state', _stateController.text);
    await prefs.setString('district', _districtController.text);
    await prefs.setString('gender', _selectedGender);

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );

    // Pop back to profile screen with a "true" flag
    Navigator.pop(context, true);
  }
}

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
    });
    _loadUserData(); // Reset to original values
  }
}
