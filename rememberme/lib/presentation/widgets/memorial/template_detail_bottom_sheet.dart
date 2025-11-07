import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';

enum PreviewDevice { desktop, tablet, mobile }

class TemplateDetailBottomSheet extends StatefulWidget {
  final Map<String, dynamic> template;
  final VoidCallback onSelect;

  const TemplateDetailBottomSheet({
    super.key,
    required this.template,
    required this.onSelect,
  });

  @override
  State<TemplateDetailBottomSheet> createState() =>
      _TemplateDetailBottomSheetState();
}

class _TemplateDetailBottomSheetState extends State<TemplateDetailBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PreviewDevice _selectedDevice = PreviewDevice.desktop;

  final Map<String, Color> _componentColors = {
    'header': const Color(0xFF2196F3),
    'content': const Color(0xFFFF9800),
    'gallery': const Color(0xFF9C27B0),
    'timeline': const Color(0xFF4CAF50),
    'quote': const Color(0xFFE91E63),
    'footer': const Color(0xFF00BCD4),
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Platform.isIOS
            ? CupertinoColors.systemBackground.resolveFrom(context)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildHeader(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildDeviceToggle(),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildVisualPreview(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildActionButtons(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            widget.template['icon'],
            size: 28,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.template['name'],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Platform.isIOS
                      ? CupertinoColors.label.resolveFrom(context)
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.template['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Platform.isIOS
                      ? CupertinoColors.secondaryLabel.resolveFrom(context)
                      : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceToggle() {
    if (Platform.isIOS) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
        ),
        child: CupertinoSlidingSegmentedControl<PreviewDevice>(
          groupValue: _selectedDevice,
          backgroundColor: CupertinoColors.systemGrey5.resolveFrom(context),
          thumbColor: CupertinoColors.white,
          children: {
            PreviewDevice.desktop: _buildDeviceSegment(
              Icons.computer,
              'Desktop',
              PreviewDevice.desktop,
            ),
            PreviewDevice.tablet: _buildDeviceSegment(
              Icons.tablet_mac,
              'Tablet',
              PreviewDevice.tablet,
            ),
            PreviewDevice.mobile: _buildDeviceSegment(
              Icons.phone_iphone,
              'Mobile',
              PreviewDevice.mobile,
            ),
          },
          onValueChanged: (value) {
            if (value != null) {
              setState(() => _selectedDevice = value);
            }
          },
        ),
      );
    } else {
      return SegmentedButton<PreviewDevice>(
        selected: {_selectedDevice},
        onSelectionChanged: (Set<PreviewDevice> selected) {
          setState(() => _selectedDevice = selected.first);
        },
        segments: [
          ButtonSegment(
            value: PreviewDevice.desktop,
            icon: const Icon(Icons.computer, size: 20),
            label: const Text('Desktop'),
          ),
          ButtonSegment(
            value: PreviewDevice.tablet,
            icon: const Icon(Icons.tablet_mac, size: 20),
            label: const Text('Tablet'),
          ),
          ButtonSegment(
            value: PreviewDevice.mobile,
            icon: const Icon(Icons.phone_iphone, size: 20),
            label: const Text('Mobile'),
          ),
        ],
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
        ),
      );
    }
  }

  Widget _buildDeviceSegment(
      IconData icon, String label, PreviewDevice device) {
    final isSelected = _selectedDevice == device;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? CupertinoColors.black
                : CupertinoColors.systemGrey.resolveFrom(context),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? CupertinoColors.black
                  : CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualPreview() {
    final blocks = _getTemplateBlocks(widget.template['id']);
    final deviceWidth = _getDeviceWidth();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      width: deviceWidth,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Platform.isIOS
                  ? CupertinoColors.systemGrey6.resolveFrom(context)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app,
                  size: 18,
                  color: Platform.isIOS
                      ? CupertinoColors.systemGrey.resolveFrom(context)
                      : Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tippe auf eine Komponente für Details',
                    style: TextStyle(
                      fontSize: 13,
                      color: Platform.isIOS
                          ? CupertinoColors.systemGrey.resolveFrom(context)
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Platform.isIOS
                  ? CupertinoColors.systemBackground.resolveFrom(context)
                  : Colors.white,
            ),
            child: Column(
              children: blocks.map((block) {
                return _buildVisualComponent(block);
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  double _getDeviceWidth() {
    // IMMER gleiche Breite - nur Inhalte ändern sich!
    return 400;
  }

  Widget _buildVisualComponent(Map<String, dynamic> block) {
    final color = _componentColors[block['colorKey']] ?? Colors.grey;
    final height = _getComponentHeight(block['heightKey']);

    return GestureDetector(
      onTap: () => _showComponentDetails(block),
      child: Container(
        height: height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.2),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Content Area - MAXIMUM PLATZ!
            Positioned.fill(
              top: 18, // War 22 → Jetzt 18!
              left: 8,
              right: 8,
              bottom: 18, // War 22 → Jetzt 18!
              child: _buildSimplePlaceholder(block['name'], color),
            ),
            // Label Badge - MINI
            Positioned(
              top: 2, // War 3
              left: 2, // War 3
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5, // War 6
                  vertical: 1, // War 2
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3), // War 4
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      block['icon'],
                      size: 9, // War 10
                      color: Colors.white,
                    ),
                    const SizedBox(width: 2), // War 3
                    Text(
                      block['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8, // War 9
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info Button - MINI
            Positioned(
              bottom: 2, // War 3
              right: 2, // War 3
              child: Container(
                padding: const EdgeInsets.all(2), // War 3
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1), // War 1.5
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 10, // War 11
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EINFACHER Platzhalter - passt sich an TYPE + TEMPLATE an!
  Widget _buildSimplePlaceholder(String name, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;

        // Zu klein? Zeige nur Icon (NUR bei WIRKLICH winzigen Bereichen!)
        if (availableHeight < 8 || availableWidth < 20) {
          return Center(
            child: Icon(
              Icons.crop_square,
              size: (availableHeight * 0.6).clamp(6.0, 15.0),
              color: Colors.grey[400],
            ),
          );
        }

        // Finde den Block-Type basierend auf Name
        final blocks = _getTemplateBlocks(widget.template['id']);
        final block = blocks.firstWhere(
          (b) => b['name'] == name,
          orElse: () => {'type': 'text'},
        );
        final type = block['type'] as String;
        final templateId = widget.template['id'] as String;

        // Render basierend auf TYPE und TEMPLATE
        return _buildPlaceholderForType(
          type,
          templateId,
          availableHeight,
          availableWidth,
          color,
        );
      },
    );
  }

  // Rendert Platzhalter basierend auf Typ und Template
  Widget _buildPlaceholderForType(
    String type,
    String templateId,
    double height,
    double width,
    Color color,
  ) {
    switch (type) {
      case 'header':
        return _buildHeaderPlaceholder(templateId, height, width);
      case 'title':
        return _buildTitlePlaceholder(templateId, height, width);
      case 'text':
        return _buildTextPlaceholder(templateId, height, width, color);
      case 'media':
        return _buildMediaPlaceholder(templateId, height, width);
      case 'contact':
        return _buildContactPlaceholder(templateId, height, width, color);
      default:
        return _buildTextContent(height, width);
    }
  }

  // ===== HEADER PLATZHALTER =====
  Widget _buildHeaderPlaceholder(
      String templateId, double height, double width) {
    switch (templateId) {
      case 'classic':
        // Klassisch: Eleganter Frame mit Portrait
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Rahmen-Dekoration
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[400]!, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Portrait-Icon
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: (height * 0.3).clamp(40.0, 60.0),
                      height: (height * 0.3).clamp(40.0, 60.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[400]!, width: 3),
                      ),
                      child: Icon(
                        Icons.person,
                        size: (height * 0.2).clamp(25.0, 40.0),
                        color: Colors.grey[400],
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      case 'modern':
        // Modern: Dynamischer Hero mit Overlay-Effekt
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Muster im Hintergrund
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: CustomPaint(
                    painter: _GridPatternPainter(),
                  ),
                ),
              ),
              // Hero-Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.panorama_horizontal,
                      size: (height * 0.35).clamp(40.0, 70.0),
                      color: Colors.white,
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            height: 2,
                            width: 40,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Overlay unten
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent
                      ],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

      case 'nature':
        // Natur: Organische Formen + Natur-Icons
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFA5D6A7), Color(0xFF81C784), Color(0xFF66BB6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Wolken/Hügel im Hintergrund
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(width, height * 0.3),
                  painter: _WavePatternPainter(),
                ),
              ),
              // Natur-Icons
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wb_sunny,
                      size: (height * 0.15).clamp(20.0, 35.0),
                      color: Colors.amber[300],
                    ),
                    SizedBox(width: 20),
                    Icon(
                      Icons.landscape,
                      size: (height * 0.3).clamp(35.0, 60.0),
                      color: Colors.green[800],
                    ),
                    SizedBox(width: 20),
                    Icon(
                      Icons.park,
                      size: (height * 0.2).clamp(25.0, 45.0),
                      color: Colors.green[700],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        // Fallback: Einfacher Gradient mit Icon
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.grey[300]!, Colors.grey[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Icon(
              Icons.landscape,
              size: (height * 0.4).clamp(30.0, 60.0),
              color: Colors.grey[400],
            ),
          ),
        );
    }
  }

  // ===== TITLE PLATZHALTER =====
  Widget _buildTitlePlaceholder(
      String templateId, double height, double width) {
    switch (templateId) {
      case 'classic':
        // Klassisch: 2 zentrierte Zeilen mit Trennlinie
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: (height * 0.35).clamp(8.0, 14.0),
                width: (width * 0.6).clamp(80.0, 140.0),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: (height * 0.15).clamp(4.0, 8.0)),
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              SizedBox(height: (height * 0.15).clamp(4.0, 8.0)),
              Container(
                height: (height * 0.25).clamp(6.0, 10.0),
                width: (width * 0.4).clamp(60.0, 100.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );

      case 'modern':
        // Modern: Info-Karten Grid - GARANTIERT SICHTBAR!
        final columns = _selectedDevice == PreviewDevice.desktop ? 3 : 2;
        final cardWidth = (width / columns - 10).clamp(50.0, 100.0);
        final cardHeight = (height * 0.8).clamp(35.0, 55.0);

        return Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(columns, (index) {
              return Container(
                width: cardWidth,
                height: cardHeight,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[100]!, Colors.orange[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[300]!, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: (cardHeight * 0.35).clamp(14.0, 22.0),
                      height: (cardHeight * 0.35).clamp(14.0, 22.0),
                      decoration: BoxDecoration(
                        color: Colors.orange[400],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        [
                          Icons.cake,
                          Icons.favorite,
                          Icons.calendar_today
                        ][index % 3],
                        size: (cardHeight * 0.2).clamp(10.0, 16.0),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: (cardHeight * 0.12).clamp(3.0, 6.0)),
                    Container(
                      height: (cardHeight * 0.12).clamp(3.0, 6.0),
                      width: cardWidth * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.orange[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: (cardHeight * 0.08).clamp(2.0, 4.0)),
                    Container(
                      height: (cardHeight * 0.1).clamp(3.0, 5.0),
                      width: cardWidth * 0.45,
                      decoration: BoxDecoration(
                        color: Colors.orange[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );

      case 'nature':
        // Natur: Portrait + Zitat kombiniert
        final portraitSize = (height * 0.65).clamp(30.0, 50.0);

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Portrait
              Container(
                width: portraitSize,
                height: portraitSize,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [Colors.green[100]!, Colors.green[200]!],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green[400]!, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: (portraitSize * 0.6).clamp(18.0, 30.0),
                  color: Colors.green[700],
                ),
              ),
              SizedBox(width: 16),
              // Zitat
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.pink[200]!, width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.format_quote,
                      size: (height * 0.2).clamp(10.0, 16.0),
                      color: Colors.pink[300],
                    ),
                    SizedBox(height: 4),
                    Container(
                      height: (height * 0.15).clamp(4.0, 7.0),
                      width: (width * 0.35).clamp(50.0, 90.0),
                      decoration: BoxDecoration(
                        color: Colors.pink[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 3),
                    Container(
                      height: (height * 0.12).clamp(3.0, 6.0),
                      width: (width * 0.25).clamp(40.0, 70.0),
                      decoration: BoxDecoration(
                        color: Colors.pink[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

      default:
        return _buildTitleContent(height, width);
    }
  }

  // ===== TEXT PLATZHALTER =====
  Widget _buildTextPlaceholder(
      String templateId, double height, double width, Color color) {
    switch (templateId) {
      case 'classic':
        // Klassisch: Elegante Textzeilen mit Absätzen
        final lineHeight = (height / 15).clamp(5.0, 8.0);
        final maxLines = 4;
        final lineCount =
            (height / (lineHeight + 5)).floor().clamp(3, maxLines);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(lineCount, (index) {
              final widthFactor = [0.85, 0.9, 0.75, 0.8][index % 4];
              final isNewParagraph = index == 2;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: isNewParagraph ? 8 : 4,
                  top: isNewParagraph ? 8 : 0,
                ),
                child: Container(
                  height: lineHeight,
                  width: (width * widthFactor).clamp(60.0, 250.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        );

      case 'modern':
        // Modern: Timeline - GARANTIERT SICHTBAR!
        final eventCount = _selectedDevice == PreviewDevice.desktop ? 3 : 2;
        final dotSize = (height * 0.12).clamp(8.0, 12.0);
        final lineHeight = (height * 0.1).clamp(6.0, 10.0);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(eventCount, (index) {
              return Padding(
                padding:
                    EdgeInsets.only(bottom: index < eventCount - 1 ? 10 : 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline-Punkt mit Ring
                    Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: BoxDecoration(
                        color: Colors.green[400],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    // Event-Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Datum/Jahr
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Container(
                            height: (lineHeight * 0.6).clamp(4.0, 7.0),
                            width: 30,
                            color: Colors.green[400],
                          ),
                        ),
                        SizedBox(height: 4),
                        // Titel
                        Container(
                          height: lineHeight,
                          width: (width * 0.45).clamp(60.0, 140.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        SizedBox(height: 3),
                        // Beschreibung
                        Container(
                          height: (lineHeight * 0.75).clamp(5.0, 8.0),
                          width: (width * 0.35).clamp(50.0, 110.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
        );

      case 'nature':
        // Natur: Fließender Text mit Blatt-Icons
        final lineHeight = (height / 15).clamp(5.0, 8.0);
        final maxLines = 3;
        final lineCount =
            (height / (lineHeight + 6)).floor().clamp(2, maxLines);

        return Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blatt-Icon als Dekoration
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.eco,
                  size: (lineHeight * 2).clamp(12.0, 18.0),
                  color: Colors.green[400],
                ),
              ),
              SizedBox(width: 10),
              // Textzeilen
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(lineCount, (index) {
                  final widthFactor = [0.7, 0.75, 0.6][index % 3];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Container(
                      height: lineHeight,
                      width: (width * widthFactor).clamp(50.0, 180.0),
                      decoration: BoxDecoration(
                        color: Colors.green[200],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );

      default:
        return _buildTextContent(height, width);
    }
  }

  // ===== MEDIA PLATZHALTER =====
  Widget _buildMediaPlaceholder(
      String templateId, double height, double width) {
    final columns = _selectedDevice == PreviewDevice.desktop ? 3 : 2;
    final itemSize = (width / columns - 10).clamp(30.0, 80.0);
    final rows = (height / (itemSize + 10)).floor().clamp(1, 2);
    final itemCount = (columns * rows).clamp(4, 6);

    switch (templateId) {
      case 'classic':
        // Klassisch: Elegante Galerie mit Rahmen
        return Center(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(itemCount, (index) {
              return Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[350]!, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: (itemSize * 0.45).clamp(18.0, 35.0),
                        color: Colors.grey[400],
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );

      case 'modern':
        // Modern: Stylisches Grid mit Hover-Effekt-Andeutung
        return Center(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(itemCount, (index) {
              return Container(
                width: itemSize,
                height: itemSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[200]!, Colors.purple[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.2),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        [
                          Icons.photo,
                          Icons.videocam,
                          Icons.music_note
                        ][index % 3],
                        size: (itemSize * 0.4).clamp(16.0, 32.0),
                        color: Colors.purple[600],
                      ),
                    ),
                    // Play-Button Overlay für Videos
                    if (index % 3 == 1)
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            width: (itemSize * 0.25).clamp(12.0, 20.0),
                            height: (itemSize * 0.25).clamp(12.0, 20.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              size: (itemSize * 0.15).clamp(8.0, 14.0),
                              color: Colors.purple[600],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        );

      case 'nature':
        // Natur: Organische Galerie mit Polaroid-Style
        return Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(itemCount, (index) {
              return Transform.rotate(
                angle: (index % 2 == 0 ? -0.05 : 0.05),
                child: Container(
                  width: itemSize,
                  height: itemSize * 1.15,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Container(
                          margin: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.photo_camera,
                              size: (itemSize * 0.35).clamp(14.0, 28.0),
                              color: Colors.green[300],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          color: Colors.white,
                          child: Center(
                            child: Container(
                              height: 2,
                              width: itemSize * 0.4,
                              color: Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );

      default:
        return _buildGalleryContent(height, width);
    }
  }

  // ===== CONTACT PLATZHALTER =====
  Widget _buildContactPlaceholder(
      String templateId, double height, double width, Color color) {
    switch (templateId) {
      case 'classic':
        // Klassisch: Elegante Nachrichten-Karte
        final avatarSize = (height * 0.3).clamp(22.0, 32.0);
        final lineHeight = (height * 0.12).clamp(6.0, 10.0);

        return Center(
          child: Container(
            padding: EdgeInsets.all((height * 0.15).clamp(8.0, 12.0)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue[200]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar mit Ring
                Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[300]!, Colors.blue[400]!],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    size: (avatarSize * 0.6).clamp(14.0, 20.0),
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: (width * 0.05).clamp(10.0, 14.0)),
                // Text-Content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Container(
                      height: lineHeight,
                      width: (width * 0.35).clamp(70.0, 110.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    SizedBox(height: (height * 0.06).clamp(3.0, 5.0)),
                    // Nachricht
                    Container(
                      height: (lineHeight * 0.8).clamp(5.0, 8.0),
                      width: (width * 0.28).clamp(60.0, 90.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: (height * 0.04).clamp(2.0, 4.0)),
                    // Datum
                    Container(
                      height: (lineHeight * 0.65).clamp(4.0, 6.0),
                      width: (width * 0.2).clamp(40.0, 60.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: (width * 0.03).clamp(8.0, 12.0)),
                // Heart Icon
                Icon(
                  Icons.favorite_border,
                  size: (height * 0.15).clamp(12.0, 18.0),
                  color: Colors.blue[300],
                ),
              ],
            ),
          ),
        );

      case 'modern':
        // Modern: Social Feed Card mit Actions
        final avatarSize = (height * 0.28).clamp(20.0, 30.0);
        final lineHeight = (height * 0.1).clamp(6.0, 9.0);

        return Center(
          child: Container(
            padding: EdgeInsets.all((height * 0.12).clamp(8.0, 12.0)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan[50]!, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.cyan[200]!, width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header mit Avatar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.cyan[300]!, Colors.cyan[500]!],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: (avatarSize * 0.6).clamp(12.0, 18.0),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: lineHeight,
                          width: (width * 0.3).clamp(60.0, 100.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 3),
                        Container(
                          height: (lineHeight * 0.7).clamp(4.0, 6.0),
                          width: (width * 0.2).clamp(40.0, 70.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // Action-Icons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.favorite_border,
                        size: 14, color: Colors.cyan[600]),
                    SizedBox(width: 12),
                    Icon(Icons.chat_bubble_outline,
                        size: 14, color: Colors.cyan[600]),
                    SizedBox(width: 12),
                    Icon(Icons.share_outlined,
                        size: 14, color: Colors.cyan[600]),
                  ],
                ),
              ],
            ),
          ),
        );

      case 'nature':
        // Natur: Erinnerungs-Buch mit organischem Design
        return Center(
          child: Container(
            padding: EdgeInsets.all((height * 0.18).clamp(10.0, 14.0)),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.brown[400]!, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(2, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Buch-Icon
                Icon(
                  Icons.auto_stories,
                  size: (height * 0.3).clamp(18.0, 28.0),
                  color: Colors.brown[600],
                ),
                SizedBox(height: 8),
                // Titel
                Container(
                  height: (height * 0.12).clamp(6.0, 9.0),
                  width: (width * 0.45).clamp(80.0, 130.0),
                  decoration: BoxDecoration(
                    color: Colors.brown[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 6),
                // Zeilen mit Blättern
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, size: 10, color: Colors.green[600]),
                    SizedBox(width: 6),
                    Container(
                      height: (height * 0.08).clamp(4.0, 6.0),
                      width: (width * 0.3).clamp(60.0, 90.0),
                      decoration: BoxDecoration(
                        color: Colors.brown[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

      default:
        return _buildMessageContent(height, width, color);
    }
  }

  Widget _buildHeroContent(double height, double width) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[300]!, Colors.grey[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Icon(
          Icons.landscape,
          size: (height * 0.4).clamp(30.0, 60.0),
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildTitleContent(double height, double width) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: (height * 0.35).clamp(8.0, 14.0),
            width: (width * 0.6).clamp(60.0, 120.0),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: (height * 0.1).clamp(3.0, 6.0)),
          Container(
            height: (height * 0.25).clamp(6.0, 10.0),
            width: (width * 0.4).clamp(40.0, 80.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent(double height, double width) {
    final lineHeight = (height / 15).clamp(5.0, 8.0);

    // Desktop: mehr Zeilen (3-4), Mobile: weniger Zeilen (2-3)
    final maxLines = _selectedDevice == PreviewDevice.desktop ? 4 : 3;
    final lineCount = (height / (lineHeight + 4)).floor().clamp(2, maxLines);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(lineCount, (index) {
          final widthFactor = [0.9, 0.85, 0.7, 0.8][index % 4];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              height: lineHeight,
              width: (width * widthFactor).clamp(40.0, 250.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInfoCardsContent(double height, double width) {
    // Desktop: 3 Spalten, Tablet/Mobile: 2 Spalten
    final columns = _selectedDevice == PreviewDevice.desktop ? 3 : 2;
    final itemWidth = (width / columns - 8).clamp(35.0, 80.0);
    final itemHeight = (height / 2.5).clamp(30.0, 50.0);

    return Center(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: List.generate(columns, (index) {
          return Container(
            width: itemWidth,
            height: itemHeight,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: (itemWidth * 0.35).clamp(12.0, 20.0),
                  height: (itemWidth * 0.35).clamp(12.0, 20.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(height: (itemHeight * 0.1).clamp(2.0, 6.0)),
                Container(
                  height: (itemHeight * 0.15).clamp(4.0, 8.0),
                  width: itemWidth * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.grey[350],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGalleryContent(double height, double width) {
    // Desktop: 3 Spalten, Tablet/Mobile: 2 Spalten
    final columns = _selectedDevice == PreviewDevice.desktop ? 3 : 2;
    final itemSize = (width / columns - 8).clamp(25.0, 70.0);
    final itemCount = (columns * (height / itemSize).floor()).clamp(4, 6);

    return Center(
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: List.generate(itemCount, (index) {
          return Container(
            width: itemSize,
            height: itemSize,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.image_outlined,
              size: (itemSize * 0.5).clamp(15.0, 35.0),
              color: Colors.grey[400],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimelineContent(double height, double width, Color color) {
    // Desktop: 3 Events, Tablet/Mobile: 2 Events
    final eventCount = _selectedDevice == PreviewDevice.desktop
        ? (height / 30).floor().clamp(2, 3)
        : 2;
    final dotSize = (height * 0.1).clamp(6.0, 10.0);
    final lineHeight = (height * 0.08).clamp(5.0, 8.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(eventCount, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < eventCount - 1 ? 8 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: lineHeight,
                      width: (width * 0.5).clamp(50.0, 150.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(height: 3),
                    Container(
                      height: (lineHeight * 0.8).clamp(4.0, 6.0),
                      width: (width * 0.35).clamp(40.0, 100.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPortraitContent(double height, double width) {
    final portraitSize = (height * 0.7).clamp(50.0, 80.0);

    return Center(
      child: Container(
        width: portraitSize,
        height: portraitSize,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[400]!, width: 2),
        ),
        child: Icon(
          Icons.person_outline,
          size: (portraitSize * 0.6).clamp(30.0, 50.0),
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildQuoteContent(double height, double width) {
    final iconSize = (height * 0.25).clamp(16.0, 24.0);
    final lineHeight = (height * 0.12).clamp(6.0, 10.0);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.format_quote,
            size: iconSize,
            color: Colors.grey[400],
          ),
          SizedBox(height: (height * 0.08).clamp(4.0, 8.0)),
          Container(
            height: lineHeight,
            width: (width * 0.75).clamp(80.0, 140.0),
            decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: (height * 0.05).clamp(3.0, 6.0)),
          Container(
            height: lineHeight,
            width: (width * 0.6).clamp(60.0, 110.0),
            decoration: BoxDecoration(
              color: Colors.grey[350],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: (height * 0.08).clamp(4.0, 8.0)),
          Container(
            height: (lineHeight * 0.8).clamp(5.0, 8.0),
            width: (width * 0.35).clamp(40.0, 70.0),
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(double height, double width, Color color) {
    final avatarSize = (height * 0.35).clamp(20.0, 28.0);
    final lineHeight = (height * 0.12).clamp(6.0, 10.0);

    return Center(
      child: Container(
        padding: EdgeInsets.all((height * 0.12).clamp(6.0, 10.0)),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                size: (avatarSize * 0.6).clamp(12.0, 18.0),
                color: Colors.white,
              ),
            ),
            SizedBox(width: (width * 0.05).clamp(8.0, 12.0)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: lineHeight,
                  width: (width * 0.4).clamp(60.0, 100.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: (height * 0.05).clamp(2.0, 4.0)),
                Container(
                  height: (lineHeight * 0.8).clamp(5.0, 8.0),
                  width: (width * 0.3).clamp(50.0, 80.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getComponentHeight(String heightKey) {
    final baseHeights = {
      'xl': 180.0,
      'large': 140.0,
      'medium': 90.0,
      'small': 60.0,
    };

    final multiplier = _selectedDevice == PreviewDevice.desktop
        ? 1.0
        : _selectedDevice == PreviewDevice.tablet
            ? 0.85
            : 0.75;

    return (baseHeights[heightKey] ?? 90.0) * multiplier;
  }

  void _showComponentDetails(Map<String, dynamic> block) {
    final color = _componentColors[block['colorKey']] ?? Colors.grey;

    if (Platform.isIOS) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(block['icon'], size: 20, color: color),
              const SizedBox(width: 8),
              Text(block['name']),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              block['description'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Verstanden'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(block['icon'], size: 22, color: color),
              const SizedBox(width: 12),
              Text(block['name']),
            ],
          ),
          content: Text(block['description']),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Verstanden'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    if (Platform.isIOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoButton.filled(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSelect();
            },
            child: const Text(
              'Dieses Design verwenden',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Andere Designs ansehen',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSelect();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Dieses Design verwenden',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[300]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Andere Designs ansehen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      );
    }
  }

  List<Map<String, dynamic>> _getTemplateBlocks(String templateId) {
    // 5 UNIVERSELLE Elemente - Namen ändern sich je nach Template
    switch (templateId) {
      case 'classic':
        return [
          {
            'name': 'Klassischer Header',
            'type': 'header', // Universeller Typ
            'icon': Icons.wallpaper,
            'colorKey': 'header',
            'heightKey': 'xl',
            'description':
                'Traditioneller Header mit elegantem Foto im klassischen Stil.',
          },
          {
            'name': 'Titel & Lebensdaten',
            'type': 'title', // Universeller Typ
            'icon': Icons.title,
            'colorKey': 'content',
            'heightKey': 'small',
            'description':
                'Name und wichtige Lebensdaten in klassischer Typografie.',
          },
          {
            'name': 'Lebensgeschichte',
            'type': 'text', // Universeller Typ
            'icon': Icons.article,
            'colorKey': 'content',
            'heightKey': 'medium',
            'description': 'Ausführlicher Text über das Leben in Absatzform.',
          },
          {
            'name': 'Fotogalerie',
            'type': 'media', // Universeller Typ
            'icon': Icons.photo_library,
            'colorKey': 'gallery',
            'heightKey': 'large',
            'description': 'Klassische Bildergalerie mit Erinnerungsfotos.',
          },
          {
            'name': 'Kondolenz-Bereich',
            'type': 'contact', // Universeller Typ
            'icon': Icons.message,
            'colorKey': 'footer',
            'heightKey': 'medium',
            'description': 'Bereich für Beileidsbekundungen und Nachrichten.',
          },
        ];

      case 'modern':
        return [
          {
            'name': 'Hero Banner',
            'type': 'header', // Universeller Typ
            'icon': Icons.panorama,
            'colorKey': 'header',
            'heightKey': 'xl',
            'description':
                'Moderner Fullscreen-Header mit beeindruckendem Bild.',
          },
          {
            'name': 'Info-Karten',
            'type': 'title', // Universeller Typ (aber mit Karten-Style!)
            'icon': Icons.dashboard,
            'colorKey': 'content',
            'heightKey': 'small',
            'description': 'Moderne Karten mit Lebensdaten in Grid-Layout.',
          },
          {
            'name': 'Interaktive Timeline',
            'type': 'text', // Universeller Typ (aber als Timeline!)
            'icon': Icons.timeline,
            'colorKey': 'timeline',
            'heightKey': 'medium',
            'description': 'Moderne Zeitleiste mit wichtigen Lebensstationen.',
          },
          {
            'name': 'Medien-Grid',
            'type': 'media', // Universeller Typ
            'icon': Icons.grid_view,
            'colorKey': 'gallery',
            'heightKey': 'large',
            'description': 'Dynamisches Grid mit Fotos und Videos.',
          },
          {
            'name': 'Social Feed',
            'type': 'contact', // Universeller Typ (aber modern!)
            'icon': Icons.chat_bubble,
            'colorKey': 'footer',
            'heightKey': 'medium',
            'description': 'Moderner Feed für Nachrichten und Erinnerungen.',
          },
        ];

      case 'nature':
        return [
          {
            'name': 'Natur-Panorama',
            'type': 'header', // Universeller Typ
            'icon': Icons.landscape,
            'colorKey': 'header',
            'heightKey': 'xl',
            'description': 'Beruhigendes Naturbild als Hintergrund.',
          },
          {
            'name': 'Portrait mit Zitat',
            'type': 'title', // Universeller Typ (Portrait + Zitat!)
            'icon': Icons.format_quote,
            'colorKey': 'quote',
            'heightKey': 'small',
            'description': 'Portraitfoto mit inspirierendem Lebensmotto.',
          },
          {
            'name': 'Lebensweg',
            'type': 'text', // Universeller Typ
            'icon': Icons.auto_stories,
            'colorKey': 'content',
            'heightKey': 'medium',
            'description': 'Erzählung des Lebenswegs mit Naturverbindung.',
          },
          {
            'name': 'Naturmomente',
            'type': 'media', // Universeller Typ
            'icon': Icons.camera_alt,
            'colorKey': 'gallery',
            'heightKey': 'large',
            'description': 'Fotos von besonderen Momenten in der Natur.',
          },
          {
            'name': 'Erinnerungsbuch',
            'type': 'contact', // Universeller Typ
            'icon': Icons.favorite,
            'colorKey': 'footer',
            'heightKey': 'medium',
            'description': 'Digitales Buch für gemeinsame Erinnerungen.',
          },
        ];

      default:
        return [];
    }
  }
}

// ===== CUSTOM PAINTERS (außerhalb der State-Klasse!) =====

// Hilfsmaler für Grid-Muster
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 30) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Hilfsmaler für Wellen-Muster
class _WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green[600]!.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.5,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
