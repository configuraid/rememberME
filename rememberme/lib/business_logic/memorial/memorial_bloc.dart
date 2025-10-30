import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/memorial_repository.dart';
import 'memorial_event.dart';
import 'memorial_state.dart';

class MemorialBloc extends Bloc<MemorialEvent, MemorialState> {
  final MemorialRepository memorialRepository;

  MemorialBloc({required this.memorialRepository})
      : super(MemorialState.initial()) {
    // Gedenkseiten laden
    on<MemorialLoadRequested>(_onLoadMemorials);

    // Einzelne Gedenkseite laden
    on<MemorialDetailLoadRequested>(_onLoadMemorialDetail);

    // Neue Gedenkseite erstellen
    on<MemorialCreateRequested>(_onCreateMemorial);

    // Gedenkseite aktualisieren
    on<MemorialUpdateRequested>(_onUpdateMemorial);

    // Gedenkseite löschen
    on<MemorialDeleteRequested>(_onDeleteMemorial);

    // Content-Block hinzufügen
    on<MemorialContentBlockAddRequested>(_onAddContentBlock);

    // Content-Block aktualisieren
    on<MemorialContentBlockUpdateRequested>(_onUpdateContentBlock);

    // Content-Block löschen
    on<MemorialContentBlockDeleteRequested>(_onDeleteContentBlock);

    // Gedenkseite veröffentlichen
    on<MemorialPublishRequested>(_onPublishMemorial);

    // Gruppenmitglied einladen
    on<MemorialInviteMemberRequested>(_onInviteMember);

    // Views erhöhen
    on<MemorialIncrementViewRequested>(_onIncrementView);
  }

  // Gedenkseiten laden Handler
  Future<void> _onLoadMemorials(
    MemorialLoadRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(MemorialState.loading());

    try {
      final memorials =
          await memorialRepository.getMemorialsByUserId(event.userId);
      emit(MemorialState.loaded(memorials));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Laden der Gedenkseiten: ${e.toString()}'));
    }
  }

  // Einzelne Gedenkseite laden Handler
  Future<void> _onLoadMemorialDetail(
    MemorialDetailLoadRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.loading));

    try {
      final memorial =
          await memorialRepository.getMemorialById(event.memorialId);

      if (memorial != null) {
        emit(state.copyWith(
          status: MemorialStatus.loaded,
          selectedMemorial: memorial,
        ));
      } else {
        emit(MemorialState.error('Gedenkseite nicht gefunden'));
      }
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Laden der Gedenkseite: ${e.toString()}'));
    }
  }

  // Neue Gedenkseite erstellen Handler
  Future<void> _onCreateMemorial(
    MemorialCreateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.creating));

    try {
      final newMemorial = await memorialRepository.createMemorial(
        ownerId: event.ownerId,
        name: event.name,
        templateId: event.templateId,
        birthDate: event.birthDate,
        deathDate: event.deathDate,
      );

      // Alle Gedenkseiten neu laden
      final memorials =
          await memorialRepository.getMemorialsByUserId(event.ownerId);

      emit(MemorialState.success(
        'Gedenkseite erfolgreich erstellt',
        memorials: memorials,
      ).copyWith(selectedMemorial: newMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Erstellen der Gedenkseite: ${e.toString()}'));
    }
  }

  // Gedenkseite aktualisieren Handler
  Future<void> _onUpdateMemorial(
    MemorialUpdateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      final updatedMemorial =
          await memorialRepository.updateMemorial(event.memorial);

      // Liste aktualisieren
      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Gedenkseite erfolgreich aktualisiert',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Aktualisieren der Gedenkseite: ${e.toString()}'));
    }
  }

  // Gedenkseite löschen Handler
  Future<void> _onDeleteMemorial(
    MemorialDeleteRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.deleting));

    try {
      await memorialRepository.deleteMemorial(event.memorialId);

      // Liste aktualisieren
      final updatedMemorials =
          state.memorials.where((m) => m.id != event.memorialId).toList();

      emit(MemorialState.success(
        'Gedenkseite erfolgreich gelöscht',
        memorials: updatedMemorials,
      ));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Löschen der Gedenkseite: ${e.toString()}'));
    }
  }

  // Content-Block hinzufügen Handler
  Future<void> _onAddContentBlock(
    MemorialContentBlockAddRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      final updatedMemorial = await memorialRepository.addContentBlock(
        event.memorialId,
        event.block,
      );

      // Liste aktualisieren
      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Inhalt erfolgreich hinzugefügt',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Hinzufügen des Inhalts: ${e.toString()}'));
    }
  }

  // Content-Block aktualisieren Handler
  Future<void> _onUpdateContentBlock(
    MemorialContentBlockUpdateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      final updatedMemorial = await memorialRepository.updateContentBlock(
        event.memorialId,
        event.block,
      );

      // Liste aktualisieren
      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Inhalt erfolgreich aktualisiert',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Aktualisieren des Inhalts: ${e.toString()}'));
    }
  }

  // Content-Block löschen Handler
  Future<void> _onDeleteContentBlock(
    MemorialContentBlockDeleteRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      final updatedMemorial = await memorialRepository.deleteContentBlock(
        event.memorialId,
        event.blockId,
      );

      // Liste aktualisieren
      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Inhalt erfolgreich gelöscht',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Löschen des Inhalts: ${e.toString()}'));
    }
  }

  // Gedenkseite veröffentlichen Handler
  Future<void> _onPublishMemorial(
    MemorialPublishRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.publishing));

    try {
      final publishedMemorial =
          await memorialRepository.publishMemorial(event.memorialId);

      // Liste aktualisieren
      final updatedMemorials = state.memorials.map((m) {
        return m.id == publishedMemorial.id ? publishedMemorial : m;
      }).toList();

      emit(MemorialState.success(
        'Gedenkseite erfolgreich veröffentlicht',
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: publishedMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Veröffentlichen der Gedenkseite: ${e.toString()}'));
    }
  }

  // Gruppenmitglied einladen Handler
  Future<void> _onInviteMember(
    MemorialInviteMemberRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      await memorialRepository.inviteGroupMember(
        memorialId: event.memorialId,
        userEmail: event.userEmail,
        role: event.role,
      );

      emit(state.copyWith(
        status: MemorialStatus.success,
        successMessage: 'Einladung erfolgreich versendet',
      ));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Einladen des Mitglieds: ${e.toString()}'));
    }
  }

  // Views erhöhen Handler
  Future<void> _onIncrementView(
    MemorialIncrementViewRequested event,
    Emitter<MemorialState> emit,
  ) async {
    try {
      await memorialRepository.incrementViewCount(event.memorialId);

      // Optional: Memorial neu laden um aktuelle View-Count zu zeigen
      final memorial =
          await memorialRepository.getMemorialById(event.memorialId);

      if (memorial != null && state.selectedMemorial?.id == memorial.id) {
        emit(state.copyWith(selectedMemorial: memorial));
      }
    } catch (e) {
      // Fehler bei View-Count sind nicht kritisch, daher nur loggen
      print('Fehler beim Erhöhen der Views: $e');
    }
  }
}
