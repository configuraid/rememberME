import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../business_logic/memorial/memorial_bloc.dart';
import '../../../business_logic/memorial/memorial_event.dart';
import '../../../business_logic/memorial/memorial_state.dart';
import '../../../business_logic/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';

class MemorialCreateScreen extends StatefulWidget {
  const MemorialCreateScreen({super.key});

  @override
  State<MemorialCreateScreen> createState() => _MemorialCreateScreenState();
}

class _MemorialCreateScreenState extends State<MemorialCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _deathDate;
  String _selectedTemplate = 'classic';

  final List<Map<String, dynamic>> _templates = [
    {
      'id': 'classic',
      'name': 'Klassisch',
      'description': 'Zeitloses, elegantes Design',
      'icon': Icons.auto_awesome,
    },
    {
      'id': 'modern',
      'name': 'Modern',
      'description': 'Minimalistisch und zeitgemäß',
      'icon': Icons.light_mode,
    },
    {
      'id': 'nature',
      'name': 'Natur',
      'description': 'Mit natürlichen Elementen',
      'icon': Icons.nature,
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _selectBirthDate() async {
    if (Platform.isIOS) {
      _showIOSDatePicker(
        initialDate: _birthDate ?? DateTime(1950),
        onDateChanged: (date) {
          setState(() => _birthDate = date);
        },
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _birthDate ?? DateTime(1950),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() => _birthDate = picked);
      }
    }
  }

  void _selectDeathDate() async {
    if (Platform.isIOS) {
      _showIOSDatePicker(
        initialDate: _deathDate ?? DateTime.now(),
        onDateChanged: (date) {
          setState(() => _deathDate = date);
        },
      );
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _deathDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() => _deathDate = picked);
      }
    }
  }

  void _showIOSDatePicker({
    required DateTime initialDate,
    required Function(DateTime) onDateChanged,
  }) {
    DateTime tempDate = initialDate;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Abbrechen'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoButton(
                  child: const Text('Fertig'),
                  onPressed: () {
                    onDateChanged(tempDate);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: initialDate,
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (date) {
                  tempDate = date;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _createMemorial() {
    if (_formKey.currentState?.validate() ?? false) {
      final userId = context.read<AuthBloc>().state.user?.id;

      if (userId == null) {
        _showError('Benutzer nicht gefunden');
        return;
      }

      context.read<MemorialBloc>().add(
            MemorialCreateRequested(
              ownerId: userId,
              name: _nameController.text.trim(),
              templateId: _selectedTemplate,
              birthDate: _birthDate,
              deathDate: _deathDate,
            ),
          );
    }
  }

  void _showError(String message) {
    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Fehler'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemorialBloc, MemorialState>(
      listener: (context, state) {
        if (state.status == MemorialStatus.success) {
          // Erfolgreich erstellt - zurück zum Dashboard
          Navigator.of(context).pop();
        } else if (state.hasError) {
          _showError(state.errorMessage ?? 'Ein Fehler ist aufgetreten');
        }
      },
      child: Platform.isIOS ? _buildIOSView() : _buildAndroidView(),
    );
  }

  // ===== ANDROID VIEW =====
  Widget _buildAndroidView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gedenkseite erstellen'),
        elevation: 0,
      ),
      body: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          if (state.status == MemorialStatus.creating) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // Name Input
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name der Person *',
                      hintText: 'z.B. Max Mustermann',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitte geben Sie einen Namen ein';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Geburtsdatum
                  _buildDateField(
                    label: 'Geburtsdatum',
                    date: _birthDate,
                    onTap: _selectBirthDate,
                    icon: Icons.cake_outlined,
                  ),
                  const SizedBox(height: 16),

                  // Sterbedatum
                  _buildDateField(
                    label: 'Sterbedatum',
                    date: _deathDate,
                    onTap: _selectDeathDate,
                    icon: Icons.event_outlined,
                  ),
                  const SizedBox(height: 32),

                  // Template Auswahl
                  Text(
                    'Design wählen',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._templates.map((template) {
                    return _buildTemplateCard(template);
                  }),
                  const SizedBox(height: 32),

                  // Erstellen Button
                  ElevatedButton(
                    onPressed: _createMemorial,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Gedenkseite erstellen',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== iOS VIEW =====
  Widget _buildIOSView() {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Gedenkseite erstellen'),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      ),
      child: SafeArea(
        child: BlocBuilder<MemorialBloc, MemorialState>(
          builder: (context, state) {
            if (state.status == MemorialStatus.creating) {
              return const Center(
                child: CupertinoActivityIndicator(radius: 20),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 32),

                    // Name Input
                    CupertinoTextField(
                      controller: _nameController,
                      placeholder: 'Name der Person *',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.person, size: 20),
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: CupertinoColors.separator.resolveFrom(context),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Geburtsdatum
                    _buildIOSDateField(
                      label: 'Geburtsdatum',
                      date: _birthDate,
                      onTap: _selectBirthDate,
                      icon: CupertinoIcons.calendar,
                    ),
                    const SizedBox(height: 16),

                    // Sterbedatum
                    _buildIOSDateField(
                      label: 'Sterbedatum',
                      date: _deathDate,
                      onTap: _selectDeathDate,
                      icon: CupertinoIcons.calendar_badge_minus,
                    ),
                    const SizedBox(height: 32),

                    // Template Auswahl
                    Text(
                      'Design wählen',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navLargeTitleTextStyle
                          .copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 16),
                    ..._templates.map((template) {
                      return _buildTemplateCard(template);
                    }),
                    const SizedBox(height: 32),

                    // Erstellen Button
                    CupertinoButton.filled(
                      onPressed: _createMemorial,
                      child: const Text(
                        'Gedenkseite erstellen',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===== GEMEINSAME WIDGETS =====

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Erstelle eine Gedenkseite',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Bewahre die Erinnerungen für immer',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null
              ? '${date.day}.${date.month}.${date.year}'
              : 'Datum wählen',
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildIOSDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: CupertinoColors.systemGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.day}.${date.month}.${date.year}'
                        : 'Datum wählen',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null
                          ? CupertinoColors.label.resolveFrom(context)
                          : CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 20,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    final isSelected = _selectedTemplate == template['id'];

    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = template['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Platform.isIOS
                  ? CupertinoColors.systemBackground.resolveFrom(context)
                  : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Platform.isIOS
                    ? CupertinoColors.separator.resolveFrom(context)
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                template['icon'],
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    template['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Platform.isIOS
                    ? CupertinoIcons.check_mark_circled_solid
                    : Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
