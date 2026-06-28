import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hireasy_mobile/core/api/api_endpoints.dart';
import 'package:hireasy_mobile/core/api/api_error_message.dart';
import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/logout_usecase.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/manage_document_usecase.dart';
import 'package:hireasy_mobile/features/auth/domain/usecase/update_profile_image_usecase.dart';
import 'package:hireasy_mobile/features/auth/presentation/pages/login_screen.dart';
import 'package:hireasy_mobile/features/jobs/presentation/providers/current_profile_provider.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: profile.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ProfileError(
            message: error.toString(),
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (user) {
            if (user == null) {
              return _ProfileError(
                message: 'Unable to find the current user.',
                onRetry: () => ref.invalidate(currentProfileProvider),
              );
            }

            return RefreshIndicator(
              onRefresh: () => ref.refresh(currentProfileProvider.future),
              child: _ProfileContent(
                user: user,
                onUploadDocument: () => _uploadDocument(context, ref),
                onDownloadDocument: () =>
                    _downloadDocument(context, ref, user.document),
                onDeleteDocument: () => _deleteDocument(context, ref),
                onUploadProfilePicture: () =>
                    _uploadProfilePicture(context, ref),
                onLogout: () => _logout(context, ref),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to log in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    _showProgress(context, 'Logging out...');
    try {
      await ref.read(logoutUsecaseProvider).call();
    } finally {
      if (context.mounted) {
        _closeProgress(context);
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref) async {
    var progressVisible = false;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedDocumentExtensions.toList(),
        allowMultiple: false,
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null) {
        throw const FormatException('Unable to read the selected document.');
      }

      if (!context.mounted) return;
      _showProgress(context, 'Uploading document...');
      progressVisible = true;
      final user = await ref
          .read(documentUsecaseProvider)
          .upload(fileName: file.name, bytes: bytes);
      if (!context.mounted) return;
      _closeProgress(context);
      progressVisible = false;
      ref.invalidate(currentProfileProvider);
      _showMessage(
        context,
        user == null
            ? 'Unable to upload the document.'
            : 'Document uploaded successfully.',
        isError: user == null,
      );
    } on DioException catch (error) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(
        context,
        apiErrorMessage(error, fallback: 'Unable to upload the document.'),
        isError: true,
      );
    } on FormatException catch (error) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(context, error.message, isError: true);
    } catch (_) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(
        context,
        'Unable to upload the document.',
        isError: true,
      );
    }
  }

  Future<void> _uploadProfilePicture(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final source = await _pickImageSource(context);
    if (source == null || !context.mounted) return;

    var progressVisible = false;
    try {
      final image = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (image == null) return;

      if (!context.mounted) return;
      _showProgress(context, 'Uploading profile picture...');
      progressVisible = true;
      final user = await ref
          .read(updateProfileImageUsecaseProvider)
          .call(
            UpdateProfileImageUsecaseParams(
              fileName: image.name,
              bytes: await image.readAsBytes(),
            ),
          );
      if (!context.mounted) return;
      _closeProgress(context);
      progressVisible = false;
      ref.invalidate(currentProfileProvider);
      _showMessage(
        context,
        user == null
            ? 'Unable to upload the profile picture.'
            : 'Profile picture updated successfully.',
        isError: user == null,
      );
    } on DioException catch (error) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(
        context,
        apiErrorMessage(
          error,
          fallback: 'Unable to upload the profile picture.',
        ),
        isError: true,
      );
    } on FormatException catch (error) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(context, error.message, isError: true);
    } catch (_) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(
        context,
        'Unable to upload the profile picture.',
        isError: true,
      );
    }
  }

  Future<ImageSource?> _pickImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _downloadDocument(
    BuildContext context,
    WidgetRef ref,
    UserDocumentEntity? document,
  ) async {
    if (document == null || !document.downloadAvailable) return;
    var progressVisible = false;

    try {
      _showProgress(context, 'Downloading document...');
      progressVisible = true;
      final bytes = await ref.read(documentUsecaseProvider).download();
      if (!context.mounted) return;
      _closeProgress(context);
      progressVisible = false;

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save document',
        fileName: document.originalName,
        bytes: bytes,
      );
      if (!context.mounted || path == null) return;
      _showMessage(context, 'Document saved successfully.');
    } on DioException catch (error) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(
        context,
        apiErrorMessage(error, fallback: 'Unable to download the document.'),
        isError: true,
      );
    }
  }

  Future<void> _deleteDocument(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text(
          'This removes your private verification document from your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    var progressVisible = false;
    try {
      _showProgress(context, 'Deleting document...');
      progressVisible = true;
      await ref.read(documentUsecaseProvider).delete();
      if (!context.mounted) return;
      _closeProgress(context);
      progressVisible = false;
      ref.invalidate(currentProfileProvider);
      _showMessage(context, 'Document deleted successfully.');
    } on DioException catch (error) {
      if (!context.mounted) return;
      if (progressVisible) _closeProgress(context);
      _showMessage(
        context,
        apiErrorMessage(error, fallback: 'Unable to delete the document.'),
        isError: true,
      );
    }
  }

  void _showProgress(BuildContext context, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 18),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _closeProgress(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showMessage(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
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
}

class _ProfileContent extends StatelessWidget {
  final AuthEntity user;
  final VoidCallback onUploadDocument;
  final VoidCallback onDownloadDocument;
  final VoidCallback onDeleteDocument;
  final VoidCallback onUploadProfilePicture;
  final VoidCallback onLogout;

  const _ProfileContent({
    required this.user,
    required this.onUploadDocument,
    required this.onDownloadDocument,
    required this.onDeleteDocument,
    required this.onUploadProfilePicture,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isCompany = user.role.trim().toLowerCase() == 'company';
    final status = user.status.trim().toLowerCase();
    final isVerified = status == 'verified';
    final displayName = isCompany
        ? _valueOrFallback(user.companyName, 'Company')
        : [
            user.firstName?.trim(),
            user.lastName?.trim(),
          ].whereType<String>().where((name) => name.isNotEmpty).join(' ');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 48),
            Text(
              isCompany ? 'Company Profile' : 'User Profile',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout, color: Colors.red, size: 28),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              _ProfileImage(
                imageUrl: user.profileImage,
                fallbackText: displayName.isEmpty ? '?' : displayName[0],
              ),
              _VerificationBadge(status: status),
              Positioned(
                right: 2,
                top: 2,
                child: _ProfileImageEditButton(
                  onPressed: onUploadProfilePicture,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildField(
          isCompany ? 'Company Name' : 'Name',
          displayName.isEmpty ? 'Not provided' : displayName,
        ),
        _buildField('Email', _valueOrFallback(user.email, 'Not provided')),
        _buildField(
          'Contact No.',
          _valueOrFallback(user.contactNo, 'Not provided'),
        ),
        _buildField('Address', _valueOrFallback(user.address, 'Not provided')),
        _buildField('Account Role', _capitalize(user.role)),
        _buildField('Account Status', _capitalize(user.status)),
        const SizedBox(height: 2),
        _DocumentSection(
          document: user.document,
          isVerified: isVerified,
          onUpload: onUploadDocument,
          onDownload: onDownloadDocument,
          onDelete: onDeleteDocument,
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF223E7F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Edit Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 50),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            child: Text(value, style: const TextStyle(fontSize: 15)),
          ),
        ],
      ),
    );
  }

  static String _valueOrFallback(String? value, String fallback) {
    final cleanValue = value?.trim() ?? '';
    return cleanValue.isEmpty ? fallback : cleanValue;
  }

  static String _capitalize(String value) {
    final cleanValue = value.trim();
    if (cleanValue.isEmpty) return 'Not provided';
    return '${cleanValue[0].toUpperCase()}${cleanValue.substring(1)}';
  }
}

class _VerificationBadge extends StatelessWidget {
  final String status;

  const _VerificationBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isVerified = status == 'verified';
    final label = status.isEmpty
        ? 'Pending'
        : '${status[0].toUpperCase()}${status.substring(1)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xFF27854B) : const Color(0xFFE09A22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.check_rounded : Icons.schedule_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'KYC verified' : label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileImageEditButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ProfileImageEditButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF223E7F),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.photo_camera_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

class _DocumentSection extends StatelessWidget {
  final UserDocumentEntity? document;
  final bool isVerified;
  final VoidCallback onUpload;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _DocumentSection({
    required this.document,
    required this.isVerified,
    required this.onUpload,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasDocument = document != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD9DDE5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document?.documentType == 'company_document'
                ? 'Company Document'
                : 'Resume',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          Text(
            isVerified
                ? 'Your account is verified.'
                : hasDocument
                ? 'Document submitted. Waiting for verification.'
                : 'Upload a document to request account verification.',
            style: const TextStyle(
              color: Color(0xFF6F7480),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          if (hasDocument) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF223E7F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    document!.originalName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  _formatSize(document!.size),
                  style: const TextStyle(
                    color: Color(0xFF777C86),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (document!.downloadAvailable)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download'),
                    ),
                  ),
                if (document!.downloadAvailable) const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB42318),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
          if (!isVerified || !hasDocument) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onUpload,
                icon: Icon(
                  hasDocument
                      ? Icons.edit_outlined
                      : Icons.upload_file_outlined,
                ),
                label: Text(hasDocument ? 'Replace document' : 'Add document'),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'PDF, DOC, DOCX, JPG or PNG • Maximum 5 MB',
            style: TextStyle(color: Color(0xFF8A8F99), fontSize: 11),
          ),
        ],
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _ProfileImage extends StatelessWidget {
  final String? imageUrl;
  final String fallbackText;

  const _ProfileImage({required this.imageUrl, required this.fallbackText});

  @override
  Widget build(BuildContext context) {
    final cleanImageUrl = imageUrl?.trim() ?? '';
    final resolvedImageUrl = _resolveProfileImageUrl(cleanImageUrl);
    return Container(
      width: 110,
      height: 110,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE4E9F3),
        border: Border.all(color: const Color(0xFF223E7F)),
      ),
      child: cleanImageUrl.isEmpty
          ? _fallback()
          : Image.network(
              resolvedImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            ),
    );
  }

  String _resolveProfileImageUrl(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri != null && uri.hasScheme) return imageUrl;

    final baseUri = Uri.parse(ApiEndpoints.baseUrl);
    final origin = '${baseUri.scheme}://${baseUri.authority}';
    final cleanImageUrl = imageUrl.replaceAll('\\', '/');
    if (cleanImageUrl.startsWith('/')) return '$origin$cleanImageUrl';
    return '$origin/$cleanImageUrl';
  }

  Widget _fallback() {
    return Center(
      child: Text(
        fallbackText.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF223E7F),
          fontSize: 38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProfileError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Color(0xFF7A8498),
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
