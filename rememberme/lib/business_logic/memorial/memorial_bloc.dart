import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/memorial_repository.dart';
import '../../data/repositories/invitation_repository.dart';
import '../../data/repositories/qr_code_repository.dart';
import '../../data/services/firebase_storage_service.dart';
import 'memorial_event.dart';
import 'memorial_state.dart';

class MemorialBloc extends Bloc<MemorialEvent, MemorialState> {
  final MemorialRepository memorialRepository;
  final InvitationRepository invitationRepository;
  final FirebaseStorageService storageService;
  final QrCodeRepository qrCodeRepository;

  MemorialBloc({
    required this.memorialRepository,
    required this.invitationRepository,
    required this.storageService,
    required this.qrCodeRepository,
  }) : super(MemorialState.initial()) {
    // Memorial CRUD
    on<MemorialLoadRequested>(_onLoadMemorials);
    on<MemorialDetailLoadRequested>(_onLoadMemorialDetail);
    on<MemorialSelected>(_onMemorialSelected);
    on<MemorialsClearRequested>(_onClearMemorials);
    on<MemorialCreateRequested>(_onCreateMemorial);
    on<MemorialUpdateRequested>(_onUpdateMemorial);
    on<MemorialDeleteRequested>(_onDeleteMemorial);

    // Visibility & Status
    on<MemorialVisibilityToggleRequested>(_onToggleVisibility);
    on<MemorialPublishRequested>(_onPublishMemorial);
    on<MemorialUnpublishRequested>(_onUnpublishMemorial);

    // Content Blocks
    on<MemorialContentBlockAddRequested>(_onAddContentBlock);
    on<MemorialContentBlockUpdateRequested>(_onUpdateContentBlock);
    on<MemorialContentBlockDeleteRequested>(_onDeleteContentBlock);

    // Invitations
    on<MemorialInviteCreateRequested>(_onCreateInvite);
    on<MemorialInviteRedeemRequested>(_onRedeemInvite);
    on<MemorialInviteRevokeRequested>(_onRevokeInvite);

    // Members
    on<MemorialMemberRemoveRequested>(_onRemoveMember);
    on<MemorialMembersLoadRequested>(_onLoadMembers);
  }

  // ========================================
  // LOAD MEMORIALS
  // ========================================

  Future<void> _onLoadMemorials(
    MemorialLoadRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(MemorialState.loading());

    try {
      debugPrint('📚 MemorialBloc - Lade Memorials für User: ${event.userId}');

      final memorials =
          await memorialRepository.getMemorialsForUser(event.userId);

      debugPrint('✅ MemorialBloc - ${memorials.length} Memorials geladen');
      emit(MemorialState.loaded(memorials));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error(
          'Fehler beim Laden der Gedenkseiten: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMemorialDetail(
    MemorialDetailLoadRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.loading));

    try {
      debugPrint('🔍 MemorialBloc - Lade Memorial: ${event.memorialId}');

      final memorial =
          await memorialRepository.getMemorialById(event.memorialId);

      if (memorial != null) {
        emit(state.copyWith(
          status: MemorialBlocStatus.loaded,
          selectedMemorial: memorial,
        ));
      } else {
        emit(MemorialState.error('Gedenkseite nicht gefunden'));
      }
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error(
          'Fehler beim Laden der Gedenkseite: ${e.toString()}'));
    }
  }

  // ========================================
  // SELECT MEMORIAL
  // ========================================

  void _onMemorialSelected(
    MemorialSelected event,
    Emitter<MemorialState> emit,
  ) {
    debugPrint('🎯 MemorialBloc - Memorial ausgewählt: ${event.memorial.name}');
    emit(state.copyWith(
      selectedMemorial: event.memorial,
    ));
  }

  // ========================================
  // CLEAR MEMORIALS (Logout/User-Wechsel)
  // ========================================

  void _onClearMemorials(
    MemorialsClearRequested event,
    Emitter<MemorialState> emit,
  ) {
    debugPrint('🧹 MemorialBloc - State zurückgesetzt');
    emit(MemorialState.initial());
  }

  // ========================================
  // CREATE MEMORIAL
  // ========================================

  Future<void> _onCreateMemorial(
    MemorialCreateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.creating));

    try {
      debugPrint('➕ MemorialBloc - Erstelle Memorial: ${event.name}');
      if (event.qrCodeId != null) {
        debugPrint('📱 MemorialBloc - Mit QR-Code: ${event.qrCodeId}');
      }

      // 1. Memorial erstellen
      var newMemorial = await memorialRepository.createMemorial(
        ownerId: event.ownerId,
        name: event.name,
        birthDate: event.birthDate,
        deathDate: event.deathDate,
        biography: event.biography,
        isPublic: event.isPublic,
        templateId: event.templateId,
      );

      debugPrint('✅ Memorial erstellt mit ID: ${newMemorial.id}');

      // 2. Profilbild hochladen (falls vorhanden)
      if (event.profileImage != null) {
        debugPrint('📸 Lade Profilbild hoch...');
        final profileImageUrl = await storageService.uploadMemorialProfileImage(
          memorialId: newMemorial.id,
          imageFile: event.profileImage!,
        );

        newMemorial = newMemorial.copyWith(profileImageUrl: profileImageUrl);
        await memorialRepository.updateMemorial(newMemorial);
        debugPrint('✅ Profilbild hochgeladen');
      }

      // 3. QR-Code finalisieren (status: claiming → active, memorialId setzen)
      if (event.qrCodeId != null) {
        debugPrint('🔗 MemorialBloc - Finalisiere QR-Code: ${event.qrCodeId}');

        final success = await qrCodeRepository.finalizeClaim(
          qrId: event.qrCodeId!,
          userId: event.ownerId,
          memorialId: newMemorial.id,
        );

        if (success) {
          debugPrint('✅ MemorialBloc - QR-Code aktiviert!');
          debugPrint('   - status: active');
          debugPrint('   - memorialId: ${newMemorial.id}');
        } else {
          debugPrint('⚠️ MemorialBloc - QR-Code Finalisierung fehlgeschlagen');
          // Wir werfen hier keinen Fehler, da das Memorial bereits erstellt wurde
        }
      }

      // 4. Liste neu laden
      final memorials =
          await memorialRepository.getMemorialsForUser(event.ownerId);

      debugPrint(
          '✅ MemorialBloc - Memorial komplett erstellt: ${newMemorial.id}');
      emit(MemorialState.success(
        'Gedenkseite erfolgreich erstellt',
        memorials: memorials,
      ).copyWith(selectedMemorial: newMemorial));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');

      // Falls ein QR-Code geclaimed wurde, aber das Memorial-Erstellen fehlschlägt,
      // sollten wir den Claim abbrechen
      if (event.qrCodeId != null) {
        debugPrint('🔄 Breche QR-Code Claim ab wegen Fehler...');
        await qrCodeRepository.abortClaim(
          qrId: event.qrCodeId!,
          userId: event.ownerId,
        );
      }

      emit(MemorialState.error(
          'Fehler beim Erstellen der Gedenkseite: ${e.toString()}'));
    }
  }

  // ========================================
  // UPDATE MEMORIAL
  // ========================================

  Future<void> _onUpdateMemorial(
    MemorialUpdateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      debugPrint(
          '🔄 MemorialBloc - Aktualisiere Memorial: ${event.memorial.id}');

      var memorialToSave = event.memorial;

      // Neues Profilbild hochladen?
      if (event.newProfileImage != null) {
        final newImageUrl = await storageService.uploadMemorialProfileImage(
          memorialId: event.memorial.id,
          imageFile: event.newProfileImage!,
        );
        memorialToSave = memorialToSave.copyWith(profileImageUrl: newImageUrl);
      }

      final updatedMemorial =
          await memorialRepository.updateMemorial(memorialToSave);

      // Lokale Liste aktualisieren
      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      debugPrint('✅ MemorialBloc - Memorial aktualisiert');
      emit(MemorialState.success(
        'Gedenkseite erfolgreich aktualisiert',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error('Fehler beim Aktualisieren: ${e.toString()}'));
    }
  }

  // ========================================
  // DELETE MEMORIAL
  // ========================================

  Future<void> _onDeleteMemorial(
    MemorialDeleteRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.deleting));

    try {
      debugPrint('🗑️ MemorialBloc - Lösche Memorial: ${event.memorialId}');

      // 1. QR-Code freigeben (memorialId entfernen, Owner bleibt)
      debugPrint('🔓 MemorialBloc - Gebe QR-Code frei...');
      final qrReleased = await qrCodeRepository.releaseQrCodeForMemorial(
        event.memorialId,
        event.requestingUserId,
      );
      if (qrReleased) {
        debugPrint(
            '✅ MemorialBloc - QR-Code freigegeben (memorialId entfernt)');
      }

      // 2. Profilbild löschen
      try {
        await storageService.deleteMemorialProfileImage(
            memorialId: event.memorialId);
      } catch (_) {}

      // 3. Memorial löschen
      await memorialRepository.deleteMemorial(
        memorialId: event.memorialId,
        requestingUserId: event.requestingUserId,
      );

      final updatedMemorials =
          state.memorials.where((m) => m.id != event.memorialId).toList();

      debugPrint('✅ MemorialBloc - Memorial gelöscht');
      emit(MemorialState.success(
        'Gedenkseite erfolgreich gelöscht',
        memorials: updatedMemorials,
      ));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error('Fehler beim Löschen: ${e.toString()}'));
    }
  }

  // ========================================
  // VISIBILITY & STATUS
  // ========================================

  Future<void> _onToggleVisibility(
    MemorialVisibilityToggleRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      debugPrint(
          '🔒 MemorialBloc - Ändere Sichtbarkeit: ${event.memorialId} → ${event.isPublic}');

      final updatedMemorial = await memorialRepository.updateVisibility(
        memorialId: event.memorialId,
        requestingUserId: event.requestingUserId,
        isPublic: event.isPublic,
      );

      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      final message = event.isPublic
          ? 'Gedenkseite ist jetzt öffentlich'
          : 'Gedenkseite ist jetzt privat';

      emit(MemorialState.success(message, memorials: updatedMemorials)
          .copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error(
          'Fehler beim Ändern der Sichtbarkeit: ${e.toString()}'));
    }
  }

  Future<void> _onPublishMemorial(
    MemorialPublishRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.publishing));

    try {
      debugPrint(
          '🌐 MemorialBloc - Veröffentliche Memorial: ${event.memorialId}');

      final publishedMemorial = await memorialRepository.updateStatus(
        memorialId: event.memorialId,
        status: MemorialStatus.published,
      );

      final updatedMemorials = state.memorials.map((m) {
        return m.id == publishedMemorial.id ? publishedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Gedenkseite erfolgreich veröffentlicht',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: publishedMemorial));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error('Fehler beim Veröffentlichen: ${e.toString()}'));
    }
  }

  Future<void> _onUnpublishMemorial(
    MemorialUnpublishRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      final memorial = await memorialRepository.updateStatus(
        memorialId: event.memorialId,
        status: MemorialStatus.draft,
      );

      final updatedMemorials = state.memorials.map((m) {
        return m.id == memorial.id ? memorial : m;
      }).toList();

      emit(MemorialState.success(
        'Gedenkseite ist nun ein Entwurf',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: memorial));
    } catch (e) {
      emit(MemorialState.error('Fehler: ${e.toString()}'));
    }
  }

  // ========================================
  // CONTENT BLOCKS
  // ========================================

  Future<void> _onAddContentBlock(
    MemorialContentBlockAddRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      final updatedMemorial = await memorialRepository.addContentBlock(
        memorialId: event.memorialId,
        block: event.block,
      );

      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Inhalt hinzugefügt',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error('Fehler beim Hinzufügen: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateContentBlock(
    MemorialContentBlockUpdateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      final updatedMemorial = await memorialRepository.updateContentBlock(
        memorialId: event.memorialId,
        block: event.block,
      );

      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Inhalt aktualisiert',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error('Fehler beim Aktualisieren: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteContentBlock(
    MemorialContentBlockDeleteRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      final updatedMemorial = await memorialRepository.deleteContentBlock(
        memorialId: event.memorialId,
        blockId: event.blockId,
      );

      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Inhalt gelöscht',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error('Fehler beim Löschen: ${e.toString()}'));
    }
  }

  // ========================================
  // INVITATIONS
  // ========================================

  Future<void> _onCreateInvite(
    MemorialInviteCreateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      debugPrint(
          '📨 MemorialBloc - Erstelle Einladung für: ${event.memorialId}');

      final invitation = await invitationRepository.createInvitation(
        memorialId: event.memorialId,
        invitedById: event.invitedById,
        email: event.email,
        validDays: event.validDays,
      );

      debugPrint(
          '✅ MemorialBloc - Einladung erstellt: ${invitation.inviteUrl}');
      emit(state.copyWith(
        status: MemorialBlocStatus.success,
        successMessage: 'Einladungslink erstellt',
        lastCreatedInviteUrl: invitation.inviteUrl,
      ));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error(
          'Fehler beim Erstellen der Einladung: ${e.toString()}'));
    }
  }

  Future<void> _onRedeemInvite(
    MemorialInviteRedeemRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.loading));

    try {
      debugPrint('🎫 MemorialBloc - Löse Einladung ein: ${event.token}');

      final access = await invitationRepository.redeemInvitation(
        token: event.token,
        userId: event.userId,
      );

      // Memorial laden
      final memorial =
          await memorialRepository.getMemorialById(access.memorialId);

      // Liste neu laden
      final memorials =
          await memorialRepository.getMemorialsForUser(event.userId);

      debugPrint('✅ MemorialBloc - Einladung eingelöst');
      emit(MemorialState.success(
        'Du hast jetzt Zugang zu dieser Gedenkseite',
        memorials: memorials,
      ).copyWith(selectedMemorial: memorial));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error(e.toString()));
    }
  }

  Future<void> _onRevokeInvite(
    MemorialInviteRevokeRequested event,
    Emitter<MemorialState> emit,
  ) async {
    try {
      await invitationRepository.revokeInvitation(
        invitationId: event.invitationId,
        requestingUserId: event.requestingUserId,
      );

      emit(state.copyWith(
        successMessage: 'Einladung widerrufen',
      ));
    } catch (e) {
      emit(MemorialState.error('Fehler: ${e.toString()}'));
    }
  }

  // ========================================
  // MEMBERS
  // ========================================

  Future<void> _onRemoveMember(
    MemorialMemberRemoveRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialBlocStatus.updating));

    try {
      debugPrint('👤 MemorialBloc - Entferne Member: ${event.userIdToRemove}');

      await memorialRepository.removeMember(
        memorialId: event.memorialId,
        userIdToRemove: event.userIdToRemove,
        requestingUserId: event.requestingUserId,
      );

      emit(state.copyWith(
        status: MemorialBlocStatus.success,
        successMessage: 'Mitglied entfernt',
      ));
    } catch (e) {
      debugPrint('❌ MemorialBloc - Fehler: $e');
      emit(MemorialState.error('Fehler: ${e.toString()}'));
    }
  }

  Future<void> _onLoadMembers(
    MemorialMembersLoadRequested event,
    Emitter<MemorialState> emit,
  ) async {
    try {
      final members =
          await memorialRepository.getMembersForMemorial(event.memorialId);

      emit(state.copyWith(
        currentMemorialMembers: members,
      ));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Laden der Mitglieder: ${e.toString()}'));
    }
  }
}
