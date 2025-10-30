import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/memorial_repository.dart';
import 'data/repositories/license_repository.dart';
import 'business_logic/auth/auth_bloc.dart';
import 'business_logic/memorial/memorial_bloc.dart';
import 'business_logic/license/license_bloc.dart';

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

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: memorialRepository),
        RepositoryProvider.value(value: licenseRepository),
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
        ],
        child: const MemorialApp(),
      ),
    ),
  );
}
