import 'package:hireasy_mobile/features/auth/domain/entities/auth_entity.dart';

class UserDocumentApiModel {
  final String documentType;
  final String originalName;
  final String mimeType;
  final int size;
  final DateTime? uploadedAt;
  final bool downloadAvailable;

  const UserDocumentApiModel({
    required this.documentType,
    required this.originalName,
    required this.mimeType,
    required this.size,
    this.uploadedAt,
    required this.downloadAvailable,
  });

  factory UserDocumentApiModel.fromJson(Map<String, dynamic> json) {
    return UserDocumentApiModel(
      documentType: json['documentType']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      size: _parseInt(json['size']),
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? ''),
      downloadAvailable: json['downloadAvailable'] == true,
    );
  }

  UserDocumentEntity toEntity() {
    return UserDocumentEntity(
      documentType: documentType,
      originalName: originalName,
      mimeType: mimeType,
      size: size,
      uploadedAt: uploadedAt,
      downloadAvailable: downloadAvailable,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AuthApiModel {
  final String? id;
  final String role;
  final String? firstName;
  final String? lastName;
  final String? companyName;
  final String email;
  final String contactNo;
  final String status;
  final String? password;
  final String address;
  final List<String> interestedFields;
  final String? profileImage;
  final UserDocumentApiModel? document;

  AuthApiModel({
    this.id,
    required this.role,
    this.firstName,
    this.lastName,
    this.companyName,
    required this.email,
    required this.contactNo,
    this.status = 'pending',
    this.password,
    required this.address,
    this.interestedFields = const [],
    this.profileImage,
    this.document,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'role': role,
      'email': email,
      'contactNo': contactNo,
      'password': password,
      'address': address,
    };

    if (role == 'company') {
      json['companyName'] = companyName;
    } else {
      json['firstName'] = firstName;
      json['lastName'] = lastName;
      json['interestedFields'] = interestedFields;
    }

    json.removeWhere((_, value) => value == null);
    return json;
  }

  factory AuthApiModel.fromJson(Map<String, dynamic> json) {
    return AuthApiModel(
      id: json['_id'] as String?,
      role: json['role'] as String? ?? 'user',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      companyName: json['companyName'] as String?,
      email: json['email'] as String? ?? '',
      contactNo: json['contactNo'] as String? ?? '',
      status: json['status']?.toString() ?? 'pending',
      address: json['address'] as String? ?? '',
      interestedFields:
          (json['interestedFields'] as List<dynamic>?)
              ?.map((field) => field.toString())
              .toList() ??
          const [],
      profileImage: json['profileImage'] as String?,
      document: json['document'] is Map
          ? UserDocumentApiModel.fromJson(
              Map<String, dynamic>.from(json['document'] as Map),
            )
          : null,
    );
  }

  AuthEntity toEntity() {
    return AuthEntity(
      authId: id,
      role: role,
      firstName: firstName,
      lastName: lastName,
      companyName: companyName,
      email: email,
      contactNo: contactNo,
      status: status,
      address: address,
      password: password,
      interestedFields: interestedFields,
      profileImage: profileImage,
      document: document?.toEntity(),
    );
  }

  factory AuthApiModel.fromEntity(AuthEntity entity) {
    return AuthApiModel(
      id: entity.authId,
      role: entity.role,
      firstName: entity.firstName,
      lastName: entity.lastName,
      companyName: entity.companyName,
      email: entity.email,
      password: entity.password,
      contactNo: entity.contactNo,
      status: entity.status,
      address: entity.address,
      interestedFields: entity.interestedFields,
      profileImage: entity.profileImage,
      document: entity.document == null
          ? null
          : UserDocumentApiModel(
              documentType: entity.document!.documentType,
              originalName: entity.document!.originalName,
              mimeType: entity.document!.mimeType,
              size: entity.document!.size,
              uploadedAt: entity.document!.uploadedAt,
              downloadAvailable: entity.document!.downloadAvailable,
            ),
    );
  }

  static List<AuthEntity> toEntityList(List<AuthApiModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
