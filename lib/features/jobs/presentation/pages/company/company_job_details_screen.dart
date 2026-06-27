import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_entity.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_photo_upload.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/get_job_applicants_usecase.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/update_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';
import 'package:image_picker/image_picker.dart';

final companyJobApplicantsProvider =
    FutureProvider.autoDispose.family<List<JobApplicationEntity>, String>((
      ref,
      jobId,
    ) {
      return ref.read(getJobApplicantsUsecaseProvider).call(jobId);
    });

class CompanyJobDetailsScreen extends ConsumerStatefulWidget {
  final JobEntity job;

  const CompanyJobDetailsScreen({super.key, required this.job});

  @override
  ConsumerState<CompanyJobDetailsScreen> createState() =>
      _CompanyJobDetailsScreenState();
}

class _CompanyJobDetailsScreenState
    extends ConsumerState<CompanyJobDetailsScreen> {
  late JobEntity _job;

  static const _primaryColor = Color(0xFF203E7B);
  static const _dangerColor = Color(0xFFFF1414);

  @override
  void initState() {
    super.initState();
    _job = widget.job;
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final fallbackApplications = _applications;
    final jobId = job.id?.trim() ?? '';
    final applicants = jobId.isEmpty
        ? null
        : ref.watch(companyJobApplicantsProvider(jobId));
    final applications =
        applicants?.maybeWhen(
          data: (applicants) =>
              applicants.isEmpty ? fallbackApplications : applicants,
          orElse: () => fallbackApplications,
        ) ??
        fallbackApplications;
    final appliedCount = applications.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusDot(status: job.status),
                        const Spacer(),
                        TextButton(
                          onPressed: () => _showEditJobSheet(job),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2B72FF),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(44, 32),
                          ),
                          child: const Text(
                            'Edit',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _JobPhotoGallery(photoUrls: _photoUrls),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            job.roleType.isEmpty
                                ? 'Untitled job'
                                : job.roleType,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              height: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${_formatPay(job.pay)}\$',
                                style: const TextStyle(
                                  color: Color(0xFFFF2B2B),
                                  fontSize: 26,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const TextSpan(
                                text: '/hr',
                                style: TextStyle(
                                  color: Color(0xFF6B6E75),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _LocationRow(
                      text: job.location.isEmpty
                          ? 'Location not provided'
                          : job.location,
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle('Duration'),
                    const SizedBox(height: 8),
                    Text(
                      job.shift.isEmpty ? 'Flexible shift' : job.shift,
                      style: const TextStyle(
                        color: Color(0xFF565A62),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle('Description'),
                    const SizedBox(height: 12),
                    Text(
                      job.description.trim().isEmpty
                          ? 'No description was provided for this job.'
                          : job.description,
                      style: const TextStyle(
                        color: Color(0xFF777A82),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _SectionTitle('Workers:'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '$appliedCount/${job.numberOfWorkers}',
                          style: const TextStyle(
                            color: Color(0xFF8A8D95),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: appliedCount == 0
                              ? null
                              : () => _showWorkersDialog(
                                  context,
                                  applications,
                                ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF2B72FF),
                            disabledForegroundColor: const Color(0xFFB5BAC5),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: const Size(52, 28),
                          ),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Repeat The Job',
                      color: _primaryColor,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 22),
                  Expanded(
                    child: _ActionButton(
                      label: 'Delete The Job',
                      color: _dangerColor,
                      onPressed: () => _confirmDeleteJob(job),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<JobApplicationEntity> get _applications {
    if (_job.applications.isNotEmpty) return _job.applications;
    return _job.appliedWorkers
        .map((workerId) => JobApplicationEntity(workerId: workerId))
        .toList();
  }

  List<String> get _photoUrls {
    return _job.photos
        .map((photo) => photo.trim())
        .where((photo) => photo.isNotEmpty)
        .map(_resolvePhotoUrl)
        .toList();
  }

  String _resolvePhotoUrl(String photo) {
    final uri = Uri.tryParse(photo);
    if (uri != null && uri.hasScheme) return photo;

    final baseUri = Uri.parse(ApiEndpoints.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.authority}';
    final cleanPhoto = photo.replaceAll('\\', '/');

    if (cleanPhoto.startsWith('/api/')) return '$origin$cleanPhoto';
    if (cleanPhoto.startsWith('/')) return '$origin$cleanPhoto';
    if (cleanPhoto.startsWith('uploads/')) return '$origin/$cleanPhoto';
    return '$origin/uploads/$cleanPhoto';
  }

  void _showWorkersDialog(
    BuildContext context,
    List<JobApplicationEntity> applications,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 52),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 704),
              child: _WorkersPanel(applications: applications),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditJobSheet(JobEntity job) async {
    final updatedJob = await showModalBottomSheet<JobEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => _EditJobSheet(job: job),
    );

    if (updatedJob == null || !mounted) return;
    setState(() => _job = updatedJob);
    _showMessage('Job updated successfully');
  }

  Future<void> _confirmDeleteJob(JobEntity job) async {
    final jobId = job.id?.trim();
    if (jobId == null || jobId.isEmpty) {
      _showMessage('This job does not have a valid ID.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete this job?'),
          content: const Text(
            'This action cannot be undone. Applicants will no longer see this job.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: _dangerColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final deleted = await ref.read(jobViewModelProvider.notifier).deleteJob(
      jobId,
    );
    if (!mounted) return;

    final state = ref.read(jobViewModelProvider);
    _showMessage(
      deleted
          ? state.successMessage ?? 'Job deleted successfully'
          : state.errorMessage ?? 'Unable to delete the job.',
      isError: !deleted,
    );
    ref.read(jobViewModelProvider.notifier).clearFeedback();

    if (deleted && mounted) {
      Navigator.pop(context);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB42318)
              : const Color(0xFF237A45),
        ),
      );
  }

  String _formatPay(num pay) {
    return pay == pay.roundToDouble()
        ? pay.toInt().toString()
        : pay.toStringAsFixed(2);
  }
}

class _EditJobSheet extends ConsumerStatefulWidget {
  final JobEntity job;

  const _EditJobSheet({required this.job});

  @override
  ConsumerState<_EditJobSheet> createState() => _EditJobSheetState();
}

class _EditJobSheetState extends ConsumerState<_EditJobSheet> {
  static const _shiftOptions = ['Morning', 'Night', 'Rotational', 'Full Day'];

  final _formKey = GlobalKey<FormState>();
  final _roleTypeController = TextEditingController();
  final _workersController = TextEditingController();
  final _payController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<String> _existingPhotos = [];
  final List<XFile> _selectedPhotos = [];

  String? _selectedShift;
  DateTime? _selectedJobDate;

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _roleTypeController.text = job.roleType;
    _workersController.text = job.numberOfWorkers.toString();
    _payController.text = job.pay == job.pay.roundToDouble()
        ? job.pay.toInt().toString()
        : job.pay.toString();
    _selectedShift = _shiftOptions.contains(job.shift) ? job.shift : null;
    _locationController.text = job.location;
    _selectedJobDate = DateTime.tryParse(job.jobDate);
    if (_selectedJobDate != null) {
      _jobDateController.text = _formatDisplayDate(_selectedJobDate!);
    }
    _existingPhotos.addAll(
      job.photos.map((photo) => photo.trim()).where((photo) => photo.isNotEmpty),
    );
    _descriptionController.text = job.description;
  }

  @override
  void dispose() {
    _roleTypeController.dispose();
    _workersController.dispose();
    _payController.dispose();
    _locationController.dispose();
    _jobDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      jobViewModelProvider.select((state) => state.isLoading),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 14,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 18,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Edit Job',
                        style: TextStyle(
                          color: Color(0xFF172C5B),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _EditFieldLabel(label: 'Role Type'),
                const SizedBox(height: 7),
                _buildTextField(
                  controller: _roleTypeController,
                  hintText: 'e.g. Security Guard',
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(value, 'Enter a role type'),
                ),
                const SizedBox(height: 14),
                _EditFieldLabel(label: 'No. of workers'),
                const SizedBox(height: 7),
                _buildTextField(
                  controller: _workersController,
                  hintText: 'e.g. 5',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: _validateWorkers,
                ),
                const SizedBox(height: 14),
                _EditFieldLabel(label: 'Pay'),
                const SizedBox(height: 7),
                _buildTextField(
                  controller: _payController,
                  hintText: 'e.g. 1500',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  validator: _validatePay,
                ),
                const SizedBox(height: 14),
                _EditFieldLabel(label: 'Shift'),
                const SizedBox(height: 7),
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
                const SizedBox(height: 14),
                _EditFieldLabel(label: 'Location'),
                const SizedBox(height: 7),
                _buildTextField(
                  controller: _locationController,
                  hintText: 'e.g. Kathmandu',
                  textInputAction: TextInputAction.next,
                  validator: (value) => _required(value, 'Enter a location'),
                ),
                const SizedBox(height: 14),
                _EditFieldLabel(label: 'Job Date'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _jobDateController,
                  readOnly: true,
                  onTap: isLoading ? null : _pickJobDate,
                  decoration: _inputDecoration(
                    'Select the working date',
                    suffixIcon: const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF52617D),
                      size: 20,
                    ),
                  ),
                  validator: (_) =>
                      _selectedJobDate == null ? 'Select a job date' : null,
                ),
                const SizedBox(height: 14),
                _EditFieldLabel(label: 'Job Photos', suffix: ' (up to 5)'),
                const SizedBox(height: 7),
                _EditPhotoPickerField(
                  existingPhotos: _existingPhotos,
                  newPhotos: _selectedPhotos,
                  isEnabled: !isLoading,
                  onCameraPressed: _pickFromCamera,
                  onGalleryPressed: _pickFromGallery,
                  onRemoveExisting: (photo) =>
                      setState(() => _existingPhotos.remove(photo)),
                  onRemoveNew: (photo) =>
                      setState(() => _selectedPhotos.remove(photo)),
                ),
                const SizedBox(height: 14),
                _EditFieldLabel(label: 'Description'),
                const SizedBox(height: 7),
                TextFormField(
                  controller: _descriptionController,
                  minLines: 4,
                  maxLines: 6,
                  textInputAction: TextInputAction.newline,
                  decoration: _inputDecoration('Describe the job'),
                  validator: (value) =>
                      _required(value, 'Enter a job description'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF203E7B),
                      disabledBackgroundColor: const Color(0xFF8D99B1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w700),
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

  InputDecoration _inputDecoration(String hintText, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF949494)),
      filled: true,
      fillColor: const Color(0xFFF2F2F4),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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

  Future<void> _pickJobDate() async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final initialDate = _selectedJobDate == null ||
            _selectedJobDate!.isBefore(firstDate)
        ? firstDate
        : _selectedJobDate!;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(firstDate.year + 2, firstDate.month, firstDate.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1F3D7A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF172C5B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    setState(() {
      _selectedJobDate = pickedDate;
      _jobDateController.text = _formatDisplayDate(pickedDate);
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final jobId = widget.job.id?.trim();
    if (jobId == null || jobId.isEmpty) {
      _showSheetMessage('This job does not have a valid ID.', isError: true);
      return;
    }

    final photoUploads = await _photoUploads();
    final updatedJob = await ref
        .read(jobViewModelProvider.notifier)
        .updateJob(
          jobId,
          UpdateJobParams(
            roleType: _roleTypeController.text,
            numberOfWorkers: int.parse(_workersController.text.trim()),
            pay: num.parse(_payController.text.trim()),
            shift: _selectedShift!,
            location: _locationController.text,
            jobDate: _formatApiDate(_selectedJobDate!),
            photos: List.unmodifiable(_existingPhotos),
            photoUploads: photoUploads,
            description: _descriptionController.text,
          ),
        );

    if (!mounted) return;
    final state = ref.read(jobViewModelProvider);
    if (updatedJob == null) {
      _showSheetMessage(
        state.errorMessage ?? 'Unable to update the job.',
        isError: true,
      );
      ref.read(jobViewModelProvider.notifier).clearFeedback();
      return;
    }

    ref.read(jobViewModelProvider.notifier).clearFeedback();
    Navigator.pop(context, updatedJob);
  }

  void _showSheetMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? const Color(0xFFB42318)
              : const Color(0xFF237A45),
        ),
      );
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateWorkers(String? value) {
    final workers = int.tryParse(value?.trim() ?? '');
    if (workers == null || workers <= 0) {
      return 'Enter a valid number of workers';
    }
    return null;
  }

  String? _validatePay(String? value) {
    final pay = num.tryParse(value?.trim() ?? '');
    if (pay == null || pay <= 0) return 'Enter a valid pay amount';
    return null;
  }

  String _formatApiDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickFromCamera() async {
    if (_remainingPhotoSlots <= 0) {
      _showSheetMessage('You can add at most 5 photos.', isError: true);
      return;
    }

    final photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return;

    setState(() => _selectedPhotos.add(photo));
  }

  Future<void> _pickFromGallery() async {
    final remainingSlots = _remainingPhotoSlots;
    if (remainingSlots <= 0) {
      _showSheetMessage('You can add at most 5 photos.', isError: true);
      return;
    }

    final photos = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (photos.isEmpty) return;

    setState(() {
      _selectedPhotos.addAll(photos.take(remainingSlots));
    });

    if (photos.length > remainingSlots) {
      _showSheetMessage('Only $remainingSlots more photo(s) were added.');
    }
  }

  int get _remainingPhotoSlots {
    return 5 - _existingPhotos.length - _selectedPhotos.length;
  }

  Future<List<JobPhotoUpload>> _photoUploads() async {
    final uploads = <JobPhotoUpload>[];
    for (final photo in _selectedPhotos) {
      uploads.add(
        JobPhotoUpload(fileName: photo.name, bytes: await photo.readAsBytes()),
      );
    }
    return uploads;
  }
}

class _EditFieldLabel extends StatelessWidget {
  final String label;
  final String? suffix;

  const _EditFieldLabel({required this.label, this.suffix});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFF1A1A1A),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        children: [
          if (suffix != null)
            TextSpan(
              text: suffix,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }
}

class _EditPhotoPickerField extends StatelessWidget {
  final List<String> existingPhotos;
  final List<XFile> newPhotos;
  final bool isEnabled;
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final ValueChanged<String> onRemoveExisting;
  final ValueChanged<XFile> onRemoveNew;

  const _EditPhotoPickerField({
    required this.existingPhotos,
    required this.newPhotos,
    required this.isEnabled,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final total = existingPhotos.length + newPhotos.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isEnabled ? onCameraPressed : null,
                  icon: const Icon(Icons.photo_camera_outlined, size: 19),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isEnabled ? onGalleryPressed : null,
                  icon: const Icon(Icons.photo_library_outlined, size: 19),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$total/5 selected',
            style: const TextStyle(color: Color(0xFF777C86), fontSize: 12),
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in existingPhotos)
                  InputChip(
                    label: Text(
                      _shortLabel(photo),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    avatar: const Icon(Icons.link_rounded, size: 18),
                    onDeleted: isEnabled ? () => onRemoveExisting(photo) : null,
                  ),
                for (final photo in newPhotos)
                  InputChip(
                    label: Text(
                      photo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    avatar: const Icon(Icons.image_outlined, size: 18),
                    onDeleted: isEnabled ? () => onRemoveNew(photo) : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _shortLabel(String value) {
    final uri = Uri.tryParse(value);
    final path = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : value;
    if (path.length <= 24) return path;
    return '...${path.substring(path.length - 21)}';
  }
}

class _WorkersPanel extends StatelessWidget {
  final List<JobApplicationEntity> applications;

  const _WorkersPanel({required this.applications});

  @override
  Widget build(BuildContext context) {
    final approved = _byStatus('approved');
    final accepted = _byStatus('accepted');
    final pending = _byStatus('pending');
    final rejected = _byStatus('rejected');
    final approvedWorkers = [...approved, ...accepted];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Workers',
          style: TextStyle(
            color: Color(0xFF18346F),
            fontSize: 23,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18),
        const Padding(
          padding: EdgeInsets.only(right: 20),
          child: Align(
            alignment: Alignment.centerRight,
            child: _SelectAllLabel(),
          ),
        ),
        const SizedBox(height: 4),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              _WorkerStatusSection(
                title: 'Accepted',
                color: Color(0xFF00D13B),
                workers: approvedWorkers,
              ),
              _WorkerStatusSection(
                title: 'Pending',
                color: Color(0xFFC4CF00),
                workers: pending,
              ),
              _WorkerStatusSection(
                title: 'Rejected',
                color: Color(0xFFFF0000),
                workers: rejected,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  List<JobApplicationEntity> _byStatus(String status) {
    return applications
        .where((application) => application.status.toLowerCase() == status)
        .toList();
  }
}

class _SelectAllLabel extends StatelessWidget {
  const _SelectAllLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFFC8C8C8),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          'Select All',
          style: TextStyle(color: Color(0xFF18346F), fontSize: 13),
        ),
      ],
    );
  }
}

class _WorkerStatusSection extends StatelessWidget {
  final String title;
  final Color color;
  final List<JobApplicationEntity> workers;

  const _WorkerStatusSection({
    required this.title,
    required this.color,
    required this.workers,
  });

  @override
  Widget build(BuildContext context) {
    if (workers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final worker in workers) _WorkerTile(worker: worker),
      ],
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final JobApplicationEntity worker;

  const _WorkerTile({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Color(0xFFE6E6E6),
        border: Border(
          top: BorderSide(color: Color(0xFFCDCDCD)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _WorkerAvatar(worker: worker),
          const SizedBox(width: 28),
          Expanded(
            child: Text(
              _displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 19,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _displayName {
    final name = worker.workerName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (worker.workerId.length <= 8) return 'Worker ${worker.workerId}';
    return 'Worker ${worker.workerId.substring(worker.workerId.length - 6)}';
  }
}

class _WorkerAvatar extends StatelessWidget {
  final JobApplicationEntity worker;

  const _WorkerAvatar({required this.worker});

  @override
  Widget build(BuildContext context) {
    final image = worker.workerProfileImage?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 34,
        height: 34,
        child: image == null || image.isEmpty
            ? const _WorkerAvatarFallback()
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _WorkerAvatarFallback(),
              ),
      ),
    );
  }
}

class _WorkerAvatarFallback extends StatelessWidget {
  const _WorkerAvatarFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFD4DBEA),
      child: Icon(
        Icons.person,
        color: Color(0xFF33466F),
        size: 24,
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final String status;

  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = status.trim().isEmpty ? 'In Progress' : _label(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF19C553),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B8E96), fontSize: 12),
        ),
      ],
    );
  }

  String _label(String value) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) return 'In Progress';
    return cleanValue
        .split(RegExp(r'[\s_-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _JobPhotoGallery extends StatefulWidget {
  final List<String> photoUrls;

  const _JobPhotoGallery({required this.photoUrls});

  @override
  State<_JobPhotoGallery> createState() => _JobPhotoGalleryState();
}

class _JobPhotoGalleryState extends State<_JobPhotoGallery> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final photoUrls = widget.photoUrls;

    if (photoUrls.isEmpty) {
      return const _JobImage(photoUrl: null);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: AspectRatio(
        aspectRatio: 1.32,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: photoUrls.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return _JobNetworkImage(photoUrl: photoUrls[index]);
              },
            ),
            if (photoUrls.length > 1)
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentIndex + 1}/${photoUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _JobImage extends StatelessWidget {
  final String? photoUrl;

  const _JobImage({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: AspectRatio(
        aspectRatio: 1.32,
        child: photoUrl == null
            ? const _ImagePlaceholder()
            : Image.network(
                photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, _) {
                  if (kDebugMode) {
                    debugPrint('Could not load job photo: $photoUrl ($error)');
                  }
                  return const _ImagePlaceholder();
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const ColoredBox(
                    color: Color(0xFFE9EDF5),
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
      ),
    );
  }
}

class _JobNetworkImage extends StatelessWidget {
  final String photoUrl;

  const _JobNetworkImage({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      photoUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, error, _) {
        if (kDebugMode) {
          debugPrint('Could not load job photo: $photoUrl ($error)');
        }
        return const _ImagePlaceholder();
      },
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: Color(0xFFE9EDF5),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE9EDF5),
      child: Center(
        child: Icon(
          Icons.work_outline_rounded,
          color: Color(0xFF667899),
          size: 58,
        ),
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final String text;

  const _LocationRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined, size: 18, color: Colors.black),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF52555D),
              fontSize: 17,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
