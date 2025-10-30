import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_routes.dart';
import '../../widgets/common/loading_indicator.dart';

class MemorialListScreen extends StatelessWidget {
  const MemorialListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.memorialList),
      ),
      body: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const LoadingIndicator();
          }

          if (state.hasError) {
            return Center(child: Text(state.errorMessage ?? AppStrings.error));
          }

          final memorials = state.memorials;

          if (memorials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine Gedenkseiten',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Erstellen Sie Ihre erste Gedenkseite'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: memorials.length,
            itemBuilder: (context, index) {
              final memorial = memorials[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: memorial.isPublished
                        ? AppColors.success.withOpacity(0.2)
                        : AppColors.warning.withOpacity(0.2),
                    child: Icon(
                      memorial.isPublished ? Icons.check : Icons.edit,
                      color: memorial.isPublished
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                  title: Text(memorial.name),
                  subtitle: Text(memorial.lifespan),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.memorialDetail,
                    arguments: memorial,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
