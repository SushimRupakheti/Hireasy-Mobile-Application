class UserDocumentEntity {
  final String documentType;
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime? uploadedAt;
  final bool downloadAvailable;

  const UserDocumentEntity({
    required this.documentType,
    required this.originalName,
    required this.mimeType,
    required this.size,
    this.uploadedAt,
    required this.downloadAvailable,
  });
}

class AuthEntity {
  final String? authId;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String email;
  final String contactNo;
  final String address;
  final String status;
  final String? password;
  final List<String> interestedFields;
  final String? profileImage;
  final UserDocumentEntity? document;

  const AuthEntity({
    this.authId,
    required this.role,
    this.firstName,
    this.lastName,
    this.companyName,
    required this.email,
    required this.contactNo,
    required this.address,
    this.status = 'pending',
    this.password,
    this.interestedFields = const [],
    this.profileImage,
    this.document,
  });
}
