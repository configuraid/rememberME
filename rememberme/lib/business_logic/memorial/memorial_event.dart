import 'dart:io';
import 'package:equatable/equatable.dart';
import '../../data/models/content_block_model.dart';
import '../../data/models/memorial_model.dart';

abstract class MemorialEvent extends Equatable {
  const MemorialEvent();

  @override
  List<Object?> get props => [];
}

// ========================================
// LOAD MEMORIALS
// ========================================

/// Lade alle Memorials für einen User
class MemorialLoadRequested extends MemorialEvent {
  final String userId;

  const MemorialLoadRequested({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Lade ein einzelnes Memorial
class MemorialDetailLoadRequested extends MemorialEvent {
  final String memorialId;

  const MemorialDetailLoadRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}

/// Memorial auswählen (für UI-Wechsel zwischen Memorials)
class MemorialSelected extends MemorialEvent {
  final MemorialModel memorial;

  const MemorialSelected({required this.memorial});

  @override
  List<Object?> get props => [memorial];
}

/// State komplett zurücksetzen (bei Logout/User-Wechsel)
class MemorialsClearRequested extends MemorialEvent {
  const MemorialsClearRequested();
}

// ========================================
// CREATE MEMORIAL
// ========================================

/// Neues Memorial erstellen
class MemorialCreateRequested extends MemorialEvent {
  final String ownerId;
  final String name;
  final DateTime? birthDate;
  final DateTime? deathDate;
  final String? biography;
  final File? profileImage;
  final bool isPublic;
  final String templateId;
  final String? qrCodeId; // NEU: QR-Code ID für Claiming

  const MemorialCreateRequested({
    required this.ownerId,
    required this.name,
    this.birthDate,
    this.deathDate,
    this.biography,
    this.profileImage,
    this.isPublic = false,
    this.templateId = 'default',
    this.qrCodeId, // NEU
  });

  @override
  List<Object?> get props => [
        ownerId,
        name,
        birthDate,
        deathDate,
        biography,
        profileImage,
        isPublic,
        templateId,
        qrCodeId, // NEU
      ];
}

// ========================================
// UPDATE MEMORIAL
// ========================================

/// Memorial aktualisieren
class MemorialUpdateRequested extends MemorialEvent {
  final MemorialModel memorial;
  final File? newProfileImage;

  const MemorialUpdateRequested({
    required this.memorial,
    this.newProfileImage,
  });

  @override
  List<Object?> get props => [memorial, newProfileImage];
}

// ========================================
// DELETE MEMORIAL
// ========================================

/// Memorial löschen (nur Owner!)
class MemorialDeleteRequested extends MemorialEvent {
  final String memorialId;
  final String requestingUserId;

  const MemorialDeleteRequested({
    required this.memorialId,
    required this.requestingUserId,
  });

  @override
  List<Object?> get props => [memorialId, requestingUserId];
}

// ========================================
// VISIBILITY & STATUS
// ========================================

/// Sichtbarkeit ändern (nur Owner!)
class MemorialVisibilityToggleRequested extends MemorialEvent {
  final String memorialId;
  final String requestingUserId;
  final bool isPublic;

  const MemorialVisibilityToggleRequested({
    required this.memorialId,
    required this.requestingUserId,
    required this.isPublic,
  });

  @override
  List<Object?> get props => [memorialId, requestingUserId, isPublic];
}

/// Memorial veröffentlichen
class MemorialPublishRequested extends MemorialEvent {
  final String memorialId;

  const MemorialPublishRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}

/// Memorial zurück zu Entwurf
class MemorialUnpublishRequested extends MemorialEvent {
  final String memorialId;

  const MemorialUnpublishRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}

// ========================================
// CONTENT BLOCKS
// ========================================

/// ContentBlock hinzufügen
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

/// ContentBlock aktualisieren
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

/// ContentBlock löschen
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
// INVITATIONS
// ========================================

/// Einladungslink erstellen
class MemorialInviteCreateRequested extends MemorialEvent {
  final String memorialId;
  final String invitedById;
  final String? email;
  final int validDays;

  const MemorialInviteCreateRequested({
    required this.memorialId,
    required this.invitedById,
    this.email,
    this.validDays = 7,
  });

  @override
  List<Object?> get props => [memorialId, invitedById, email, validDays];
}

/// Einladung einlösen
class MemorialInviteRedeemRequested extends MemorialEvent {
  final String token;
  final String userId;

  const MemorialInviteRedeemRequested({
    required this.token,
    required this.userId,
  });

  @override
  List<Object?> get props => [token, userId];
}

/// Einladung widerrufen
class MemorialInviteRevokeRequested extends MemorialEvent {
  final String invitationId;
  final String requestingUserId;

  const MemorialInviteRevokeRequested({
    required this.invitationId,
    required this.requestingUserId,
  });

  @override
  List<Object?> get props => [invitationId, requestingUserId];
}

// ========================================
// MEMBERS
// ========================================

/// Member entfernen
class MemorialMemberRemoveRequested extends MemorialEvent {
  final String memorialId;
  final String userIdToRemove;
  final String requestingUserId;

  const MemorialMemberRemoveRequested({
    required this.memorialId,
    required this.userIdToRemove,
    required this.requestingUserId,
  });

  @override
  List<Object?> get props => [memorialId, userIdToRemove, requestingUserId];
}

/// Members laden
class MemorialMembersLoadRequested extends MemorialEvent {
  final String memorialId;

  const MemorialMembersLoadRequested({required this.memorialId});

  @override
  List<Object?> get props => [memorialId];
}
