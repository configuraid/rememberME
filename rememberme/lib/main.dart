import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/memorial_repository.dart';
import 'data/repositories/license_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/page_builder_repository.dart';
import 'business_logic/auth/auth_bloc.dart';
import 'business_logic/memorial/memorial_bloc.dart';
import 'business_logic/license/license_bloc.dart';
import 'business_logic/profile/profile_bloc.dart';
import 'business_logic/page_builder/page_builder_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System-UI Styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Repositories initialisieren (später mit Firebase)
  final authRepository = AuthRepository();
  final memorialRepository = MemorialRepository();
  final licenseRepository = LicenseRepository();
  final profileRepository = ProfileRepository();
  final pageBuilderRepository = PageBuilderRepository();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: memorialRepository),
        RepositoryProvider.value(value: licenseRepository),
        RepositoryProvider.value(value: profileRepository),
        RepositoryProvider.value(value: pageBuilderRepository),
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
            ),
          ),
          BlocProvider(
            create: (context) => LicenseBloc(
              licenseRepository: context.read<LicenseRepository>(),
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
        child: const MemorialApp(),
      ),
    ),
  );
}
