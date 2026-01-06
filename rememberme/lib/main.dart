// main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/core/utils/deep_link_handler.dart';
import 'package:rememberme/data/services/qr_code_services/claiming_service.dart';

import 'app.dart';
import 'firebase_options.dart';

// Repositories
import 'data/repositories/auth_repository.dart';
import 'data/repositories/memorial_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/page_builder_repository.dart';
import 'data/repositories/invitation_repository.dart';
import 'data/repositories/qr_code_repository.dart';

// Services
import 'data/services/firebase_storage_service.dart';
import 'data/services/preview_service.dart';

// Blocs
import 'business_logic/auth/auth_bloc.dart';
import 'business_logic/memorial/memorial_bloc.dart';
import 'business_logic/profile/profile_bloc.dart';
import 'business_logic/page_builder/page_builder_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await deepLinkHandler.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  // Repositories
  final authRepository = AuthRepository();
  final memorialRepository = MemorialRepository();
  final profileRepository = ProfileRepository();
  final pageBuilderRepository = PageBuilderRepository();
  final invitationRepository = InvitationRepository();
  final qrCodeRepository = QrCodeRepository();

  // Services
  final storageService = FirebaseStorageService();
  final previewService = PreviewService();
  final claimingService = ClaimingService(
    qrCodeRepository: qrCodeRepository,
    memorialRepository: memorialRepository,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: memorialRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: pageBuilderRepository),
        RepositoryProvider.value(value: invitationRepository),
        RepositoryProvider.value(value: qrCodeRepository),
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: previewService),
        RepositoryProvider.value(value: claimingService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => MemorialBloc(
              memorialRepository: context.read<MemorialRepository>(),
              invitationRepository: context.read<InvitationRepository>(),
              storageService: context.read<FirebaseStorageService>(),
              qrCodeRepository: context.read<QrCodeRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ProfileBloc(
              profileRepository: context.read<ProfileRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => PageBuilderBloc(
              pageBuilderRepository: context.read<PageBuilderRepository>(),
            ),
          ),
        ],
        child: const RememberMeApp(),
      ),
    ),
  );
}
