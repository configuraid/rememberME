import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rememberme/business_logic/auth/auth_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_bloc.dart';
import 'package:rememberme/business_logic/memorial/memorial_event.dart';
import 'package:rememberme/business_logic/memorial/memorial_state.dart';
import '../../../presentation/widgets/memorial/template_detail_bottom_sheet.dart';
import '../../../core/constants/app_colors.dart';

enum CreateTab { details, design }

class MemorialCreateScreen extends StatefulWidget {
  const MemorialCreateScreen({super.key});

  @override
  State<MemorialCreateScreen> createState() => _MemorialCreateScreenState();
}

class _MemorialCreateScreenState extends State<MemorialCreateScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime? _birthDate;
  DateTime? _deathDate;
  String _selectedTemplate = 'classic';
  CreateTab _currentTab = CreateTab.details;

  late TabController _tabController;

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
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab =
              _tabController.index == 0 ? CreateTab.details : CreateTab.design;
        });
      }
    });

    // Listener für Name-Input um Button-State zu aktualisieren
    _nameController.addListener(() {
      setState(() {}); // Trigger rebuild für Button-Validierung
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tabController.dispose();
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
      final authState = context.read<AuthBloc>().state;
      final user = authState.user;

      if (user == null) {
        _showError('Benutzer nicht gefunden');
        return;
      }

      // ✅ Prüfe ob primaryOrganizationId vorhanden ist
      if (user.primaryOrganizationId == null) {
        _showError('Keine Organisation gefunden');
        return;
      }

      print('📝 MemorialCreateScreen - Erstelle Memorial');
      print('👤 User: ${user.name} (${user.id})');
      print('🏢 Organisation: ${user.primaryOrganizationId}');
      print('📋 Name: ${_nameController.text.trim()}');
      print('🎨 Template: $_selectedTemplate');

      // ✅ Sende Event mit organizationId
      context.read<MemorialBloc>().add(
            MemorialCreateRequested(
              organizationId: user.primaryOrganizationId!, // ✅ WICHTIG!
              ownerId: user.id,
              name: _nameController.text.trim(),
              templateId: _selectedTemplate,
              birthDate: _birthDate,
              deathDate: _deathDate,
            ),
          );
    }
  }

  // Validierung: Prüft ob alle Pflichtfelder ausgefüllt sind
  bool _isFormValid() {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasBirthDate = _birthDate != null;
    final hasDeathDate = _deathDate != null;

    return hasName && hasBirthDate && hasDeathDate;
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
        print('🎧 MemorialCreateScreen Listener - Status: ${state.status}');

        if (state.status == MemorialStatus.success) {
          print('✅ Memorial erfolgreich erstellt - navigiere zurück');
          Navigator.of(context).pop();
        } else if (state.hasError) {
          print('❌ Fehler: ${state.errorMessage}');
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildMaterialTabBar(),
        ),
      ),
      body: BlocBuilder<MemorialBloc, MemorialState>(
        builder: (context, state) {
          if (state.status == MemorialStatus.creating) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildDetailsContent(),
              _buildDesignContent(),
            ],
          );
        },
      ),
      floatingActionButton: _isFormValid()
          ? FloatingActionButton.extended(
              onPressed: _createMemorial,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.check),
              label: const Text('Erstellen'),
            )
          : FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: Colors.grey[300],
              icon: Icon(Icons.check, color: Colors.grey[500]),
              label: Text(
                'Erstellen',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
    );
  }

  Widget _buildMaterialTabBar() {
    return Container(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Angaben'),
          Tab(text: 'Design'),
        ],
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

            return Column(
              children: [
                // iOS Segmented Control
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildIOSSegmentedControl(),
                ),

                // Content
                Expanded(
                  child: _currentTab == CreateTab.details
                      ? _buildDetailsContent()
                      : _buildDesignContent(),
                ),

                // Create Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isFormValid() ? _createMemorial : null,
                      disabledColor: CupertinoColors.quaternarySystemFill
                          .resolveFrom(context),
                      child: Text(
                        'Gedenkseite erstellen',
                        style: TextStyle(
                          fontSize: 16,
                          color: _isFormValid()
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey.resolveFrom(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildIOSSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoSlidingSegmentedControl<CreateTab>(
        groupValue: _currentTab,
        backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
        thumbColor: CupertinoColors.white,
        padding: const EdgeInsets.all(0),
        children: {
          CreateTab.details: _buildSegment('Angaben', CreateTab.details),
          CreateTab.design: _buildSegment('Design', CreateTab.design),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() => _currentTab = value);
          }
        },
      ),
    );
  }

  Widget _buildSegment(String text, CreateTab tab) {
    final isSelected = _currentTab == tab;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? CupertinoColors.black
              : CupertinoColors.systemGrey.resolveFrom(context),
        ),
      ),
    );
  }

  // ===== CONTENT SECTIONS =====

  Widget _buildDetailsContent() {
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

            // Platform-specific input fields
            if (Platform.isIOS) ...[
              // iOS Name Input
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

              // iOS Date Fields
              _buildIOSDateField(
                label: 'Geburtsdatum',
                date: _birthDate,
                onTap: _selectBirthDate,
                icon: CupertinoIcons.calendar,
              ),
              const SizedBox(height: 16),

              _buildIOSDateField(
                label: 'Sterbedatum',
                date: _deathDate,
                onTap: _selectDeathDate,
                icon: CupertinoIcons.calendar_badge_minus,
              ),
            ] else ...[
              // Android Name Input
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

              // Android Date Fields
              _buildDateField(
                label: 'Geburtsdatum',
                date: _birthDate,
                onTap: _selectBirthDate,
                icon: Icons.cake_outlined,
              ),
              const SizedBox(height: 16),

              _buildDateField(
                label: 'Sterbedatum',
                date: _deathDate,
                onTap: _selectDeathDate,
                icon: Icons.event_outlined,
              ),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildDesignContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Wähle ein Design',
            style: Platform.isIOS
                ? CupertinoTheme.of(context)
                    .textTheme
                    .navLargeTitleTextStyle
                    .copyWith(fontSize: 24)
                : Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
          ),
          const SizedBox(height: 8),
          Text(
            'Du kannst das Design später jederzeit ändern',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ..._templates.map((template) {
            return _buildTemplateCard(template);
          }),
          const SizedBox(height: 80),
        ],
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
      onTap: () {
        setState(() => _selectedTemplate = template['id']);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          children: [
            // Preview-Bereich
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 140 : 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [
                          Colors.black,
                          Colors.grey[900]!,
                        ]
                      : [
                          Colors.grey[100]!,
                          Colors.grey[200]!,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Stack(
                children: [
                  // Mockup-Elemente mit Animation
                  Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 300),
                      scale: isSelected ? 1.2 : 1.0,
                      child: Icon(
                        template['icon'],
                        size: 56,
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : Colors.grey[400],
                      ),
                    ),
                  ),

                  // Decorative Pattern (nur bei selected)
                  if (isSelected)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _PatternPainter(),
                      ),
                    ),

                  // Info Button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => DraggableScrollableSheet(
                            initialChildSize: 0.85,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            builder: (context, scrollController) =>
                                TemplateDetailBottomSheet(
                              template: template,
                              onSelect: () {
                                setState(
                                    () => _selectedTemplate = template['id']);
                              },
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.15)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : Colors.grey[300]!,
                          ),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),

                  // Selected Badge
                  if (isSelected)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 400),
                        tween: Tween(begin: 0.0, end: 1.0),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.black,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Ausgewählt',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content-Bereich
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                              child: Text(template['name']),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: TextStyle(
                                fontSize: 14,
                                color: isSelected
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              child: Text(template['description']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Features Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getTemplateFeatureTags(template['id'])
                        .map((tag) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.15)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ))
                        .toList(),
                  ),

                  // "Details ansehen" nur wenn nicht selected
                  if (!isSelected) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Details ansehen',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper-Methoden
  List<String> _getTemplateFeatureTags(String templateId) {
    switch (templateId) {
      case 'classic':
        return ['Zeitlos', 'Elegant', 'Traditionell'];
      case 'modern':
        return ['Modern', 'Minimalistisch', 'Interaktiv'];
      case 'nature':
        return ['Natürlich', 'Beruhigend', 'Harmonisch'];
      default:
        return [];
    }
  }
}

// Custom Painter für dezentes Pattern (nur bei selected)
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Diagonale Linien
    for (double i = -size.height; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
