import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/create_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';

class CompanyPostJobScreen extends ConsumerStatefulWidget {
  final String? initialRoleType;

  const CompanyPostJobScreen({super.key, this.initialRoleType});

  @override
  ConsumerState<CompanyPostJobScreen> createState() =>
      _CompanyPostJobScreenState();
}

class _CompanyPostJobScreenState extends ConsumerState<CompanyPostJobScreen> {
  static const _shiftOptions = ['Morning', 'Night', 'Rotational', 'Full Day'];

  final _formKey = GlobalKey<FormState>();
  final _roleTypeController = TextEditingController();
  final _payController = TextEditingController();
  final _workersController = TextEditingController();
  final _locationController = TextEditingController();
  final _photoController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedShift;

  @override
  void initState() {
    super.initState();
    _roleTypeController.text = widget.initialRoleType?.trim() ?? '';
  }

  @override
  void dispose() {
    _roleTypeController.dispose();
    _payController.dispose();
    _workersController.dispose();
    _locationController.dispose();
    _photoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _postJob() async {
    FocusScope.of(context).unfocus();
    if (!ref.read(tokenServiceProvider).isVerified) {
      _showMessage(
        'Account is pending. Only verified accounts can post jobs.',
        isError: true,
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final photoUrl = _photoController.text.trim();
    final posted = await ref
        .read(jobViewModelProvider.notifier)
        .createJob(
          CreateJobParams(
            roleType: _roleTypeController.text,
            numberOfWorkers: int.parse(_workersController.text.trim()),
            pay: num.parse(_payController.text.trim()),
            shift: _selectedShift!,
            location: _locationController.text,
            photos: photoUrl.isEmpty ? const [] : [photoUrl],
            description: _descriptionController.text,
          ),
        );

    if (!mounted) return;
    final state = ref.read(jobViewModelProvider);
    _showMessage(
      posted
          ? state.successMessage ?? 'Job posted successfully'
          : state.errorMessage ?? 'Unable to post the job.',
      isError: !posted,
    );

    if (posted) {
      _formKey.currentState!.reset();
      _roleTypeController.clear();
      _payController.clear();
      _workersController.clear();
      _locationController.clear();
      _photoController.clear();
      _descriptionController.clear();
      setState(() => _selectedShift = null);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB3261E)
              : const Color(0xFF237A45),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      jobViewModelProvider.select((state) => state.isLoading),
    );
    final isVerified = ref.read(tokenServiceProvider).isVerified;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Post a Job',
          style: TextStyle(
            color: Color(0xFF172C5B),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel(label: 'Role Type'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _roleTypeController,
                  hintText: 'e.g. Kitchen Helper',
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(value, 'Enter a role type'),
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'Pay', suffix: ' (amount)*'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _payController,
                  hintText: 'e.g. 1500',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validatePay,
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'No. of workers'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _workersController,
                  hintText: 'e.g. 3',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: _validateWorkers,
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'Shift'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedShift,
                  decoration: _inputDecoration('Select a shift'),
                  items: _shiftOptions
                      .map(
                        (shift) =>
                            DropdownMenuItem(value: shift, child: Text(shift)),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() => _selectedShift = value),
                  validator: (value) => value == null ? 'Select a shift' : null,
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'City/Location'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _locationController,
                  hintText: 'e.g. Kathmandu',
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(value, 'Enter a location'),
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'Photo URL', suffix: ' (optional)'),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _photoController,
                  hintText: 'https://example.com/job-photo.jpg',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  validator: _validatePhotoUrl,
                ),
                const SizedBox(height: 18),
                _FieldLabel(label: 'Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 5,
                  maxLines: 7,
                  textInputAction: TextInputAction.newline,
                  decoration: _inputDecoration(
                    'Describe the role and requirements',
                  ),
                  validator: (value) =>
                      _required(value, 'Enter a job description'),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading || !isVerified ? null : _postJob,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F3D7A),
                      disabledBackgroundColor: const Color(0xFF8190AF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isVerified
                                ? 'Post the job'
                                : 'Verification required',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: _inputDecoration(hintText),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF949494)),
      filled: true,
      fillColor: const Color(0xFFF2F2F4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB3261E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
      ),
    );
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _validatePay(String? value) {
    final pay = num.tryParse(value?.trim() ?? '');
    if (pay == null || pay <= 0) return 'Enter a valid pay amount';
    return null;
  }

  String? _validateWorkers(String? value) {
    final workers = int.tryParse(value?.trim() ?? '');
    if (workers == null || workers <= 0) {
      return 'Enter a valid number of workers';
    }
    return null;
  }

  String? _validatePhotoUrl(String? value) {
    final photo = value?.trim() ?? '';
    if (photo.isEmpty) return null;
    final uri = Uri.tryParse(photo);
    if (uri == null ||
        !uri.hasAbsolutePath ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      return 'Enter a valid HTTP or HTTPS URL';
    }
    return null;
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final String? suffix;

  const _FieldLabel({required this.label, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A1A),
        ),
        children: [
          if (suffix != null)
            TextSpan(
              text: suffix,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }
}
