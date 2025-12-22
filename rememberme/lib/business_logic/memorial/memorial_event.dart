import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../data/models/auth/user_model.dart';
import '../../data/models/content_block_model.dart';
import '../../data/models/memorial_page_model.dart';

abstract class MemorialEvent extends Equatable {
  const MemorialEvent();

  @override
  List<Object?> get props => [];
}

class MemorialLoadRequested extends MemorialEvent {
  final String organizationId;

  const MemorialLoadRequested({required this.organizationId});

  @override
  List<Object?> get props => [organizationId];
}

class MemorialDetailLoadRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDetailLoadRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}

class MemorialCreateRequested extends MemorialEvent {
  final String organizationId;
  final String ownerId;
  final String name;
  final String templateId;
  final File profileImage;
  final String biography;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final bool isPublic;

  const MemorialCreateRequested({
    required this.organizationId,
    required this.ownerId,
    required this.name,
    required this.templateId,
    required this.profileImage,
    required this.biography,
    this.birthDate,
    this.deathDate,
    this.isPublic = false,
  });

  @override
  List<Object?> get props => [
        organizationId,
        ownerId,
        name,
        templateId,
        profileImage,
        biography,
        birthDate,
        deathDate,
        isPublic
      ];
}

class MemorialUpdateRequested extends MemorialEvent {
  final MemorialPageModel memorial;
  final File? newProfileImage;

  const MemorialUpdateRequested({
    required this.memorial,
    this.newProfileImage,
  });

  @override
  List<Object?> get props => [memorial, newProfileImage];
}

class MemorialDeleteRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDeleteRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}

class MemorialVisibilityToggleRequested extends MemorialEvent {
  final String memorialId;
  final bool isPublic;

  const MemorialVisibilityToggleRequested({
    required this.memorialId,
    required this.isPublic,
  });

  @override
  List<Object?> get props => [memorialId, isPublic];
}

class MemorialContentBlockAddRequested extends MemorialEvent {
  final String memorialId;
  final ContentBlock block;

  const MemorialContentBlockAddRequested({
    required this.memorialId,
    required this.block,
  });

  @override
  List<Object?> get props => [memorialId, block];
}

class MemorialContentBlockUpdateRequested extends MemorialEvent {
  final String memorialId;
  final ContentBlock block;

  const MemorialContentBlockUpdateRequested({
    required this.memorialId,
    required this.block,
  });

  @override
  List<Object?> get props => [memorialId, block];
}

class MemorialContentBlockDeleteRequested extends MemorialEvent {
  final String memorialId;
  final String blockId;

  const MemorialContentBlockDeleteRequested({
    required this.memorialId,
    required this.blockId,
  });

  @override
  List<Object?> get props => [memorialId, blockId];
}

class MemorialPublishRequested extends MemorialEvent {
  final String memorialId;

  const MemorialPublishRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}

class MemorialInviteMemberRequested extends MemorialEvent {
  final String memorialId;
  final String userEmail;
  final UserRole role;

  const MemorialInviteMemberRequested({
    required this.memorialId,
    required this.userEmail,
    required this.role,
  });

  @override
  List<Object?> get props => [memorialId, userEmail, role];
}

class MemorialIncrementViewRequested extends MemorialEvent {
  final String memorialId;

  const MemorialIncrementViewRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}
