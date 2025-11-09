import 'package:equatable/equatable.dart';
import 'package:rememberme/data/models/auth/user_model.dart';
import '../../data/models/memorial_page_model.dart';
import '../../data/models/content_block_model.dart';

abstract class MemorialEvent extends Equatable {
  const MemorialEvent();

  @override
  List<Object?> get props => [];
}

// ========================================
// LOAD EVENTS
// ========================================

/// Gedenkseiten einer Organisation laden
class MemorialLoadRequested extends MemorialEvent {
  final String organizationId;
  final String userId; // Optional: Filter nach User

  const MemorialLoadRequested({
    required this.organizationId,
    required this.userId,
  });

  @override
  List<Object?> get props => [organizationId, userId];
}

/// Einzelne Gedenkseite laden
class MemorialDetailLoadRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDetailLoadRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

// ========================================
// CREATE / UPDATE / DELETE
// ========================================

/// Neue Gedenkseite erstellen
class MemorialCreateRequested extends MemorialEvent {
  final String organizationId; // ✅ Hinzugefügt!
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

/// Gedenkseite aktualisieren
class MemorialUpdateRequested extends MemorialEvent {
  final MemorialPageModel memorial;

  const MemorialUpdateRequested(this.memorial);

  @override
  List<Object?> get props => [memorial];
}

/// Gedenkseite löschen
class MemorialDeleteRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDeleteRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

// ========================================
// CONTENT BLOCK EVENTS
// ========================================

/// Content-Block hinzufügen
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

/// Content-Block aktualisieren
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

/// Content-Block löschen
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

// ========================================
// PUBLISH & SHARE
// ========================================

/// Gedenkseite veröffentlichen
class MemorialPublishRequested extends MemorialEvent {
  final String memorialId;

  const MemorialPublishRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

/// Gruppenmitglied einladen
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

// ========================================
// ANALYTICS
// ========================================

/// Views erhöhen
class MemorialIncrementViewRequested extends MemorialEvent {
  final String memorialId;

  const MemorialIncrementViewRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}
