import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/api_service.dart';
import 'admin_drawer.dart';
import 'dashboard_screen.dart';
import '../widgets/admin_loader.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  // Profile Details
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Business Info
  final _businessNameController = TextEditingController();
  final _gstController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();

  // Security
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final response = await ApiService.getAdminSettings();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _businessNameController.text = data['business_name'] ?? '';
          _gstController.text = data['gst_number'] ?? '';
          _address1Controller.text = data['address_line_1'] ?? '';
          _address2Controller.text = data['address_line_2'] ?? '';
          _cityController.text = data['city'] ?? '';
          _stateController.text = data['state'] ?? '';
          _zipController.text = data['zip_code'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _gstController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_newPasswordController.text.isNotEmpty && _newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'business_name': _businessNameController.text,
        'gst_number': _gstController.text,
        'address_line_1': _address1Controller.text,
        'address_line_2': _address2Controller.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zip_code': _zipController.text,
      };

      if (_newPasswordController.text.isNotEmpty) {
        data['password'] = _newPasswordController.text;
      }

      try {
        final response = await ApiService.updateAdminSettings(data);
        if (response.statusCode == 200) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully!', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
          );
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } else {
          final resData = jsonDecode(response.body);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(resData['message'] ?? 'Update failed'), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update settings'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgDark = Color(0xFF121212);
    const Color cardDark = Color(0xFF1E1E1E);
    const Color goldMain = Color(0xFFD4AF37);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      },
      child: Scaffold(
        backgroundColor: bgDark,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: goldMain),
            onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
          ),
          title: const Text('ACCOUNT SETTINGS', style: TextStyle(fontWeight: FontWeight.w800, color: goldMain, letterSpacing: 1.5, fontSize: 16)),
          backgroundColor: bgDark,
          elevation: 0,
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_open, color: goldMain),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
        endDrawer: const AdminDrawer(currentRoute: 'Settings'),
        body: _isLoading 
            ? const AdminLoader()
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Update your profile, business information, and change your password.", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                const SizedBox(height: 30),
                
                // Profile Details Section
                _buildSectionTitle('Profile Details', 'Basic contact and login information.', goldMain),
                _buildSectionCard(
                  cardDark,
                  goldMain,
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Full Name', _nameController, 'e.g. John Doe', goldMain)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildTextField('Email Address', _emailController, 'admin@example.com', goldMain, keyboardType: TextInputType.emailAddress)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Phone Number', _phoneController, 'e.g. 1234567890', goldMain, keyboardType: TextInputType.phone)),
                          const SizedBox(width: 15),
                          const Expanded(child: SizedBox()), // Empty space to match the screenshot layout
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Business Information Section
                _buildSectionTitle('Business Information', 'Details used for billing and organization display.', goldMain),
                _buildSectionCard(
                  cardDark,
                  goldMain,
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Business/Organization Name', _businessNameController, 'Organization Name', goldMain)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildTextField('GST Number (Optional)', _gstController, 'GST Number', goldMain)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildTextField('Address Line 1', _address1Controller, 'Street Address', goldMain),
                      const SizedBox(height: 20),
                      _buildTextField('Address Line 2', _address2Controller, 'Apartment, suite, etc.', goldMain),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('City', _cityController, 'City', goldMain)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildTextField('State/Province', _stateController, 'State', goldMain)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('ZIP/Postal Code', _zipController, 'ZIP Code', goldMain, keyboardType: TextInputType.number)),
                          const SizedBox(width: 15),
                          const Expanded(child: SizedBox()), // Spacer
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Security Section
                _buildSectionTitle('Security', 'Leave blank if you do not wish to change your password.', goldMain),
                _buildSectionCard(
                  cardDark,
                  goldMain,
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'New Password', 
                          _newPasswordController, 
                          'Enter new password', 
                          goldMain,
                          obscureText: _obscureNewPass,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNewPass ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600], size: 20),
                            onPressed: () => setState(() => _obscureNewPass = !_obscureNewPass),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildTextField(
                          'Confirm New Password', 
                          _confirmPasswordController, 
                          'Confirm new password', 
                          goldMain,
                          obscureText: _obscureConfirmPass,
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPass ? Icons.visibility_off : Icons.visibility, color: Colors.grey[600], size: 20),
                            onPressed: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goldMain,
                      foregroundColor: bgDark,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 5,
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle, Color goldMain) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: goldMain, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSectionCard(Color cardDark, Color goldMain, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[850]!, width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, Color goldMain, {TextInputType keyboardType = TextInputType.text, bool obscureText = false, Widget? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF121212),
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[800]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: goldMain),
            ),
          ),
        ),
      ],
    );
  }
}
