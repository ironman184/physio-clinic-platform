import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart' as ap;

/// Hardcoded clinic name → ID mapping (demo).
const Map<String, String> kDemoClinics = {
  'PhysioCare Downtown': 'clinic_001',
  'HealWell Physiotherapy': 'clinic_002',
  'MoveRight Rehab Center': 'clinic_003',
};

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedDob;
  String? _selectedClinic;

  static final _emailRegex = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('dd MMM yyyy').format(picked);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      _showError('Please select your gender.');
      return;
    }
    if (_selectedDob == null) {
      _showError('Please select your date of birth.');
      return;
    }
    if (_selectedClinic == null) {
      _showError('Please select a clinic.');
      return;
    }

    final provider = context.read<ap.AuthProvider>();
    await provider.register(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      gender: _selectedGender!.toLowerCase(),
      dob: _selectedDob!,
      clinicId: kDemoClinics[_selectedClinic]!,
    );

    if (!mounted) return;

    if (provider.status == ap.AuthStatus.error) {
      _showError(provider.errorMessage ?? 'Registration failed.');
      provider.clearError();
    }
    // On success, AuthWrapper detects the new profile and swaps to MainAppFlow.
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Consumer<ap.AuthProvider>(
          builder: (context, provider, _) {
            final isLoading = provider.status == ap.AuthStatus.loading;

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell us about you',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in your details to complete registration.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 36),
                    // ── First Name ─────────────────────────────────────
                    TextFormField(
                      controller: _firstNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'First Name *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'First name is required.';
                        }
                        if (v.trim().length < 2) {
                          return 'Must be at least 2 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── Last Name ──────────────────────────────────────
                    TextFormField(
                      controller: _lastNameController,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Last Name *',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Last name is required.';
                        }
                        if (v.trim().length < 2) {
                          return 'Must be at least 2 characters.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── Email (optional) ───────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Email (optional)',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!_emailRegex.hasMatch(v.trim())) {
                          return 'Enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // ── Gender ─────────────────────────────────────────
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Gender *',
                        prefixIcon: const Icon(Icons.wc_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: _genders
                          .map((g) => DropdownMenuItem(
                                value: g,
                                child: Text(g),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedGender = v),
                      validator: (v) =>
                          v == null ? 'Please select your gender.' : null,
                    ),
                    const SizedBox(height: 16),
                    // ── Date of Birth ──────────────────────────────────
                    GestureDetector(
                      onTap: _pickDob,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth *',
                            prefixIcon:
                                const Icon(Icons.calendar_today_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            hintText: 'Select date',
                          ),
                          controller: _dobController,
                          validator: (_) => _selectedDob == null
                              ? 'Please select your date of birth.'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ── Clinic ─────────────────────────────────────────
                    DropdownButtonFormField<String>(
                      value: _selectedClinic,
                      decoration: InputDecoration(
                        labelText: 'Clinic *',
                        prefixIcon:
                            const Icon(Icons.local_hospital_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: kDemoClinics.keys
                          .map((name) => DropdownMenuItem(
                                value: name,
                                child: Text(name),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedClinic = v),
                      validator: (v) =>
                          v == null ? 'Please select a clinic.' : null,
                    ),
                    const SizedBox(height: 44),
                    // ── Submit ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: isLoading ? null : _register,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Complete Registration',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
