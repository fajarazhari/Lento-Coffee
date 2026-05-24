import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { owner, manager, cashier, barista }

extension UserRoleX on UserRole {
  String get label => switch (this) {
    UserRole.owner   => 'Owner',
    UserRole.manager => 'Manager',
    UserRole.cashier => 'Cashier',
    UserRole.barista => 'Barista',
  };

  bool get canAccessReports   => this == UserRole.owner || this == UserRole.manager;
  bool get canManageProducts  => this == UserRole.owner || this == UserRole.manager;
  bool get canAccessKds       => true;
  bool get canCreateOrders    => this != UserRole.barista;
  bool get canChangeSettings  => this == UserRole.owner;
}

class AppUserModel extends Equatable {
  const AppUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.pin,
    this.photoUrl,
    this.themeColor = '#5D4037',
    this.isActive = true,
    this.createdAt,
    this.lastLogin,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? pin;
  final String? photoUrl;
  final String themeColor;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  factory AppUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUserModel(
      id:         doc.id,
      name:       data['name']       as String? ?? '',
      email:      data['email']      as String? ?? '',
      role:       UserRole.values.firstWhere(
        (r) => r.name == (data['role'] as String? ?? 'cashier'),
        orElse: () => UserRole.cashier,
      ),
      pin:        data['pin']        as String?,
      photoUrl:   data['photoUrl']   as String?,
      themeColor: data['themeColor'] as String? ?? '#5D4037',
      isActive:   data['isActive']   as bool? ?? true,
      createdAt:  (data['createdAt'] as Timestamp?)?.toDate(),
      lastLogin:  (data['lastLogin'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name':       name,
    'email':      email,
    'role':       role.name,
    'pin':        pin,
    'photoUrl':   photoUrl,
    'themeColor': themeColor,
    'isActive':   isActive,
    'createdAt':  createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    'lastLogin':  FieldValue.serverTimestamp(),
  };

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, 2).toUpperCase();
  }

  AppUserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? pin,
    String? photoUrl,
    String? themeColor,
    bool? isActive,
    DateTime? lastLogin,
  }) =>
      AppUserModel(
        id:         id,
        name:       name       ?? this.name,
        email:      email      ?? this.email,
        role:       role       ?? this.role,
        pin:        pin        ?? this.pin,
        photoUrl:   photoUrl   ?? this.photoUrl,
        themeColor: themeColor ?? this.themeColor,
        isActive:   isActive   ?? this.isActive,
        createdAt:  createdAt,
        lastLogin:  lastLogin  ?? this.lastLogin,
      );

  @override
  List<Object?> get props => [id, name, email, role, isActive];
}
