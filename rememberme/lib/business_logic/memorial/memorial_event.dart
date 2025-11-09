import 'package:equatable/equatable.dart';
import '../../data/models/auth/user_model.dart';
import '../../data/models/content_block_model.dart';
import '../../data/models/memorial_page_model.dart';

abstract class MemorialEvent extends Equatable {
  const MemorialEvent();

  @override
  List<Object?> get props => [];
}

// ✅ GEÄNDERT: Nutzt organizationId statt userId
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

// ✅ GEÄNDERT: Nutzt organizationId statt userId (war vorher nur implizit)
class MemorialCreateRequested extends MemorialEvent {
  final String organizationId;
  final String ownerId;
  final String name;
  final String templateId;
  final DateTime? birthDate;
  final DateTime? deathDate;

  const MemorialCreateRequested({
    required this.organizationId,
    required this.ownerId,
    required this.name,
    required this.templateId,
    this.birthDate,
    this.deathDate,
  });

  @override
  List<Object?> get props =>
      [organizationId, ownerId, name, templateId, birthDate, deathDate];
}

class MemorialUpdateRequested extends MemorialEvent {
  final MemorialPageModel memorial;

  const MemorialUpdateRequested({required this.memorial});

  @override
  List<Object?> get props => [memorial];
}

class MemorialDeleteRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDeleteRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
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
