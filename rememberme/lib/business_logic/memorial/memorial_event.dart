import 'package:equatable/equatable.dart';
import '../../data/models/memorial_page_model.dart';
import '../../data/models/content_block_model.dart';
import '../../data/models/user_model.dart';

abstract class MemorialEvent extends Equatable {
  const MemorialEvent();

  @override
  List<Object?> get props => [];
}

// Gedenkseiten eines Users laden
class MemorialLoadRequested extends MemorialEvent {
  final String userId;

  const MemorialLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

// Einzelne Gedenkseite laden
class MemorialDetailLoadRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDetailLoadRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

// Neue Gedenkseite erstellen
class MemorialCreateRequested extends MemorialEvent {
  final String ownerId;
  final String name;
  final String templateId;
  final DateTime? birthDate;
  final DateTime? deathDate;

  const MemorialCreateRequested({
    required this.ownerId,
    required this.name,
    required this.templateId,
    this.birthDate,
    this.deathDate,
  });

  @override
  List<Object?> get props => [ownerId, name, templateId, birthDate, deathDate];
}

// Gedenkseite aktualisieren
class MemorialUpdateRequested extends MemorialEvent {
  final MemorialPageModel memorial;

  const MemorialUpdateRequested(this.memorial);

  @override
  List<Object?> get props => [memorial];
}

// Gedenkseite löschen
class MemorialDeleteRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDeleteRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

// Content-Block hinzufügen
class MemorialContentBlockAddRequested extends MemorialEvent {
  final String memorialId;
  final ContentBlockModel block;

  const MemorialContentBlockAddRequested({
    required this.memorialId,
    required this.block,
  });

  @override
  List<Object?> get props => [memorialId, block];
}

// Content-Block aktualisieren
class MemorialContentBlockUpdateRequested extends MemorialEvent {
  final String memorialId;
  final ContentBlockModel block;

  const MemorialContentBlockUpdateRequested({
    required this.memorialId,
    required this.block,
  });

  @override
  List<Object?> get props => [memorialId, block];
}

// Content-Block löschen
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

// Gedenkseite veröffentlichen
class MemorialPublishRequested extends MemorialEvent {
  final String memorialId;

  const MemorialPublishRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}

// Gruppenmitglied einladen
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

// Views erhöhen
class MemorialIncrementViewRequested extends MemorialEvent {
  final String memorialId;

  const MemorialIncrementViewRequested(this.memorialId);

  @override
  List<Object?> get props => [memorialId];
}
