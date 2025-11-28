import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/memorial_repository.dart';
import 'memorial_event.dart';
import 'memorial_state.dart';

class MemorialBloc extends Bloc<MemorialEvent, MemorialState> {
  final MemorialRepository memorialRepository;

  MemorialBloc({required this.memorialRepository})
      : super(MemorialState.initial()) {
    on<MemorialLoadRequested>(_onLoadMemorials);
    on<MemorialDetailLoadRequested>(_onLoadMemorialDetail);
    on<MemorialCreateRequested>(_onCreateMemorial);
    on<MemorialUpdateRequested>(_onUpdateMemorial);
    on<MemorialDeleteRequested>(_onDeleteMemorial);
    on<MemorialVisibilityToggleRequested>(_onToggleVisibility);
    on<MemorialContentBlockAddRequested>(_onAddContentBlock);
    on<MemorialContentBlockUpdateRequested>(_onUpdateContentBlock);
    on<MemorialContentBlockDeleteRequested>(_onDeleteContentBlock);
    on<MemorialPublishRequested>(_onPublishMemorial);
    on<MemorialInviteMemberRequested>(_onInviteMember);
  }

  Future<void> _onLoadMemorials(
    MemorialLoadRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(MemorialState.loading());

    try {
      final memorials = await memorialRepository
          .getMemorialsByOrganization(event.organizationId);
      emit(MemorialState.loaded(memorials));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Laden der Gedenkseiten: ${e.toString()}'));
    }
  }

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

  Future<void> _onCreateMemorial(
    MemorialCreateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.creating));

    try {
      final newMemorial = await memorialRepository.createMemorial(
        organizationId: event.organizationId,
        ownerId: event.ownerId,
        name: event.name,
        templateId: event.templateId,
        birthDate: event.birthDate,
        deathDate: event.deathDate,
        isPublic: event.isPublic,
      );

      final memorials = await memorialRepository
          .getMemorialsByOrganization(event.organizationId);

      emit(MemorialState.success(
        'Gedenkseite erfolgreich erstellt',
        memorials: memorials,
      ).copyWith(selectedMemorial: newMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Erstellen der Gedenkseite: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateMemorial(
    MemorialUpdateRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      final updatedMemorial =
          await memorialRepository.updateMemorial(event.memorial);

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

  Future<void> _onDeleteMemorial(
    MemorialDeleteRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.deleting));

    try {
      await memorialRepository.deleteMemorial(event.memorialId);

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

  Future<void> _onToggleVisibility(
    MemorialVisibilityToggleRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      final updatedMemorial = await memorialRepository.updateMemorialVisibility(
        event.memorialId,
        event.isPublic,
      );

      final updatedMemorials = state.memorials.map((m) {
        return m.id == updatedMemorial.id ? updatedMemorial : m;
      }).toList();

      final message = event.isPublic
          ? 'Gedenkseite ist jetzt öffentlich'
          : 'Gedenkseite ist jetzt privat';

      emit(MemorialState.success(
        message,
        memorials: updatedMemorials,
      ).copyWith(selectedMemorial: updatedMemorial));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Ändern der Sichtbarkeit: ${e.toString()}'));
    }
  }

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

  Future<void> _onPublishMemorial(
    MemorialPublishRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.publishing));

    try {
      final publishedMemorial =
          await memorialRepository.publishMemorial(event.memorialId);

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

  Future<void> _onInviteMember(
    MemorialInviteMemberRequested event,
    Emitter<MemorialState> emit,
  ) async {
    emit(state.copyWith(status: MemorialStatus.updating));

    try {
      emit(state.copyWith(
        status: MemorialStatus.error,
        errorMessage:
            'Mitglieder-Einladung muss über OrganizationRepository implementiert werden',
      ));
    } catch (e) {
      emit(MemorialState.error(
          'Fehler beim Einladen des Mitglieds: ${e.toString()}'));
    }
  }
}
