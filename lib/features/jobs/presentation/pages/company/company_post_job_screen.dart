import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/token_service.dart';
import 'package:hireasy_mobile/features/jobs/domain/entities/job_photo_upload.dart';
import 'package:hireasy_mobile/features/jobs/domain/usecases/create_job_usecase.dart';
import 'package:hireasy_mobile/features/jobs/presentation/view_model/job_viemodel.dart';
import 'package:image_picker/image_picker.dart';

class CompanyPostJobScreen extends ConsumerStatefulWidget {
  final String? initialRoleType;

  const CompanyPostJobScreen({super.key, this.initialRoleType});

  @override
  ConsumerState<CompanyPostJobScreen> createState() =>
      _CompanyPostJobScreenState();
}

class _CompanyPostJobScreenState extends ConsumerState<CompanyPostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleTypeController = TextEditingController();
  final _payController = TextEditingController();
  final _workersController = TextEditingController();
  final _locationController = TextEditingController();
  final _jobDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final List<XFile> _selectedPhotos = [];
  final List<_ShiftTimeRange> _shiftRanges = [];

  TimeOfDay? _shiftStartTime;
  TimeOfDay? _shiftEndTime;
  DateTime? _selectedJobDate;

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
    _jobDateController.dispose();
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

    final photoUploads = await _photoUploads();
    final posted = await ref
        .read(jobViewModelProvider.notifier)
        .createJob(
          CreateJobParams(
            roleType: _roleTypeController.text,
            numberOfWorkers: int.parse(_workersController.text.trim()),
            pay: num.parse(_payController.text.trim()),
            shift: _formatShiftRanges(),
            location: _locationController.text,
            jobDate: _formatApiDate(_selectedJobDate!),
            photoUploads: photoUploads,
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
      _jobDateController.clear();
      _descriptionController.clear();
      setState(() {
        _shiftStartTime = null;
        _shiftEndTime = null;
        _shiftRanges.clear();
        _selectedJobDate = null;
        _selectedPhotos.clear();
      });
    }
  }

  Future<void> _pickJobDate() async {
    FocusScope.of(context).unfocus();
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedJobDate ?? firstDate,
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
                FormField<List<_ShiftTimeRange>>(
                  validator: (_) =>
                      _shiftRanges.isEmpty ? 'Add at least one shift' : null,
                  builder: (field) {
                    return _ShiftPickerField(
                      shifts: _shiftRanges,
                      startTimeText: _formatNullableTime(_shiftStartTime),
                      endTimeText: _formatNullableTime(_shiftEndTime),
                      isEnabled: !isLoading,
                      errorText: field.errorText,
                      onStartTimePressed: _pickShiftStartTime,
                      onEndTimePressed: _pickShiftEndTime,
                      onAddPressed: () {
                        _addShiftRange();
                        field.didChange(_shiftRanges);
                      },
                      onRemovePressed: (shift) {
                        setState(() => _shiftRanges.remove(shift));
                        field.didChange(_shiftRanges);
                      },
                    );
                  },
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
                _FieldLabel(label: 'Job Date'),
                const SizedBox(height: 8),
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
                const SizedBox(height: 18),
                _FieldLabel(label: 'Job Photos', suffix: ' (up to 5)'),
                const SizedBox(height: 8),
                _PhotoPickerField(
                  photos: _selectedPhotos,
                  isEnabled: !isLoading,
                  onCameraPressed: _pickFromCamera,
                  onGalleryPressed: _pickFromGallery,
                  onRemove: (photo) =>
                      setState(() => _selectedPhotos.remove(photo)),
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

  Future<void> _pickShiftStartTime() async {
    final pickedTime = await _pickShiftTime(_shiftStartTime);
    if (pickedTime == null) return;
    setState(() => _shiftStartTime = pickedTime);
  }

  Future<void> _pickShiftEndTime() async {
    final pickedTime = await _pickShiftTime(_shiftEndTime);
    if (pickedTime == null) return;
    setState(() => _shiftEndTime = pickedTime);
  }

  Future<TimeOfDay?> _pickShiftTime(TimeOfDay? initialTime) {
    FocusScope.of(context).unfocus();
    return showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Enter time',
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
  }

  void _addShiftRange() {
    final startTime = _shiftStartTime;
    final endTime = _shiftEndTime;
    if (startTime == null || endTime == null) {
      _showMessage('Select both start time and end time.', isError: true);
      return;
    }
    final startMinutes = _timeInMinutes(startTime);
    final endMinutes = _timeInMinutes(endTime);
    if (endMinutes <= startMinutes) {
      _showMessage(
        'Invalid time schedule. End time must be after start time.',
        isError: true,
      );
      return;
    }
    final overlapsExistingShift = _shiftRanges.any((shift) {
      final existingStart = _timeInMinutes(shift.start);
      final existingEnd = _timeInMinutes(shift.end);
      return startMinutes < existingEnd && endMinutes > existingStart;
    });
    if (overlapsExistingShift) {
      _showMessage(
        'Invalid time schedule. Shift times cannot overlap.',
        isError: true,
      );
      return;
    }

    setState(() {
      _shiftRanges.add(_ShiftTimeRange(start: startTime, end: endTime));
      _shiftStartTime = null;
      _shiftEndTime = null;
    });
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

  String _formatNullableTime(TimeOfDay? time) {
    return time == null ? '' : time.format(context);
  }

  String _formatShiftRanges() {
    return _shiftRanges
        .map(
          (shift) =>
              '${shift.start.format(context)} - ${shift.end.format(context)}',
        )
        .join(', ');
  }

  int _timeInMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _pickFromCamera() async {
    if (_selectedPhotos.length >= 5) {
      _showMessage('You can add at most 5 photos.', isError: true);
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
    final remainingSlots = 5 - _selectedPhotos.length;
    if (remainingSlots <= 0) {
      _showMessage('You can add at most 5 photos.', isError: true);
      return;
    }

    final photos = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (photos.isEmpty) return;

    setState(() {
      _selectedPhotos.addAll(photos.take(remainingSlots));
    });

    if (photos.length > remainingSlots) {
      _showMessage(
        'Only $remainingSlots more photo(s) were added.',
        isError: false,
      );
    }
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

class _ShiftTimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  const _ShiftTimeRange({required this.start, required this.end});
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

class _ShiftPickerField extends StatelessWidget {
  final List<_ShiftTimeRange> shifts;
  final String startTimeText;
  final String endTimeText;
  final bool isEnabled;
  final String? errorText;
  final VoidCallback onStartTimePressed;
  final VoidCallback onEndTimePressed;
  final VoidCallback onAddPressed;
  final ValueChanged<_ShiftTimeRange> onRemovePressed;

  const _ShiftPickerField({
    required this.shifts,
    required this.startTimeText,
    required this.endTimeText,
    required this.isEnabled,
    required this.errorText,
    required this.onStartTimePressed,
    required this.onEndTimePressed,
    required this.onAddPressed,
    required this.onRemovePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TimePickerButton(
                label: startTimeText.isEmpty ? 'Start time' : startTimeText,
                isPlaceholder: startTimeText.isEmpty,
                isEnabled: isEnabled,
                onPressed: onStartTimePressed,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimePickerButton(
                label: endTimeText.isEmpty ? 'End time' : endTimeText,
                isPlaceholder: endTimeText.isEmpty,
                isEnabled: isEnabled,
                onPressed: onEndTimePressed,
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: isEnabled ? onAddPressed : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F3D7A),
                  disabledBackgroundColor: const Color(0xFF8190AF),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12),
            ),
          ),
        ],
        if (shifts.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final shift in shifts)
                InputChip(
                  label: Text(
                    '${shift.start.format(context)} - '
                    '${shift.end.format(context)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  avatar: const Icon(Icons.schedule_rounded, size: 18),
                  onDeleted: isEnabled ? () => onRemovePressed(shift) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimePickerButton extends StatelessWidget {
  final String label;
  final bool isPlaceholder;
  final bool isEnabled;
  final VoidCallback onPressed;

  const _TimePickerButton({
    required this.label,
    required this.isPlaceholder,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F2F4),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                color: isEnabled
                    ? const Color(0xFF52617D)
                    : const Color(0xFF9BA4B5),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPlaceholder
                        ? const Color(0xFF949494)
                        : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPickerField extends StatelessWidget {
  final List<XFile> photos;
  final bool isEnabled;
  final VoidCallback onCameraPressed;
  final VoidCallback onGalleryPressed;
  final ValueChanged<XFile> onRemove;

  const _PhotoPickerField({
    required this.photos,
    required this.isEnabled,
    required this.onCameraPressed,
    required this.onGalleryPressed,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
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
            '${photos.length}/5 selected',
            style: const TextStyle(color: Color(0xFF777C86), fontSize: 12),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final photo in photos)
                  InputChip(
                    label: Text(
                      photo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    avatar: const Icon(Icons.image_outlined, size: 18),
                    onDeleted: isEnabled ? () => onRemove(photo) : null,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
