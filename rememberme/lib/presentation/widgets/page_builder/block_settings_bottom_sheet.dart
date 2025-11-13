import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rememberme/data/models/content_block_model.dart';
import 'package:rememberme/data/services/firebase_storage_service.dart';

class BlockSettingsBottomSheet extends StatefulWidget {
  final ContentBlock block;
  final String memorialId;
  final Function(String key, dynamic value) onUpdate;

  const BlockSettingsBottomSheet({
    super.key,
    required this.block,
    required this.memorialId,
    required this.onUpdate,
  });

  @override
  State<BlockSettingsBottomSheet> createState() =>
      _BlockSettingsBottomSheetState();
}

class _BlockSettingsBottomSheetState extends State<BlockSettingsBottomSheet> {
  late Map<String, TextEditingController> _controllers;
  late Map<String, dynamic> _localContent;

  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseStorageService _storageService = FirebaseStorageService();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    _localContent = Map.from(widget.block.content);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void didUpdateWidget(BlockSettingsBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.block != widget.block) {
      _localContent = Map.from(widget.block.content);

      _controllers.forEach((key, controller) {
        final newValue = _localContent[key];
        if (newValue != null && controller.text != newValue.toString()) {
          controller.text = newValue.toString();
        }
      });
    }
  }

  void _updateValue(String key, dynamic value) {
    setState(() {
      _localContent[key] = value;
    });
    widget.onUpdate(key, value);
  }

  T _getContent<T>(String key, T defaultValue) {
    return (_localContent[key] ?? defaultValue) as T;
  }

  TextEditingController _getController(String key, String defaultValue) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: _getContent(key, defaultValue),
      );
    }
    return _controllers[key]!;
  }

  Future<void> _handleImageUpload() async {
    if (_isUploading) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) {
        print('📷 Kein Bild ausgewählt');
        return;
      }

      setState(() => _isUploading = true);

      final String downloadUrl = await _storageService.uploadBlockImage(
        memorialId: widget.memorialId,
        blockId: widget.block.id,
        imageFile: File(image.path),
      );

      _updateValue('url', downloadUrl);

      if (mounted) {
        _showSuccessSnackBar('Bild erfolgreich hochgeladen!');
      }
    } catch (e) {
      print('Image Upload Error: $e');
      if (mounted) {
        _showErrorDialog('Fehler beim Hochladen', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _handleGalleryImagesUpload() async {
    if (_isUploading) return;

    try {
      // Get current images
      final List<String> currentImages = List<String>.from(
        _getContent<List>('images', []),
      );

      // Calculate how many more images can be added
      final int remaining = 6 - currentImages.length;

      if (remaining <= 0) {
        _showErrorDialog(
          'Maximum erreicht',
          'Du kannst maximal 6 Bilder in einer Galerie haben.',
        );
        return;
      }

      // Pick multiple images
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) {
        print('📷 Keine Bilder ausgewählt');
        return;
      }

      // Limit to remaining slots
      final imagesToUpload = images.take(remaining).toList();

      if (images.length > remaining) {
        _showErrorDialog(
          'Zu viele Bilder',
          'Du kannst nur noch $remaining ${remaining == 1 ? "Bild" : "Bilder"} hinzufügen. Die ersten $remaining werden hochgeladen.',
        );
      }

      setState(() => _isUploading = true);

      // Convert XFile to File
      final List<File> imageFiles =
          imagesToUpload.map((xfile) => File(xfile.path)).toList();

      // Upload to Firebase Storage
      final List<String> downloadUrls =
          await _storageService.uploadGalleryImages(
        memorialId: widget.memorialId,
        blockId: widget.block.id,
        imageFiles: imageFiles,
      );

      // Add new URLs to existing images
      final updatedImages = [...currentImages, ...downloadUrls];
      _updateValue('images', updatedImages);

      if (mounted) {
        _showSuccessSnackBar(
          '${downloadUrls.length} ${downloadUrls.length == 1 ? "Bild" : "Bilder"} erfolgreich hochgeladen! ✅',
        );
      }
    } catch (e) {
      print('Gallery Upload Error: $e');
      if (mounted) {
        _showErrorDialog('Fehler beim Hochladen', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  // Remove image from gallery
  void _removeGalleryImage(int index) {
    final List<String> currentImages = List<String>.from(
      _getContent<List>('images', []),
    );

    if (index >= 0 && index < currentImages.length) {
      currentImages.removeAt(index);
      _updateValue('images', currentImages);
    }
  }

  void _showSuccessSnackBar(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Hinweis'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      BlockTypeInfo.getIcon(widget.block.type),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${BlockTypeInfo.getTitle(widget.block.type)} bearbeiten',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: _buildSettings(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSettings() {
    switch (widget.block.type) {
      case ContentBlockType.header:
        return _buildHeaderSettings();
      case ContentBlockType.text:
        return _buildTextSettings();
      case ContentBlockType.image:
        return _buildImageSettings();
      case ContentBlockType.gallery:
        return _buildGallerySettings();
      case ContentBlockType.quote:
        return _buildQuoteSettings();
      case ContentBlockType.divider:
        return _buildDividerSettings();
      case ContentBlockType.video:
        return _buildVideoSettings();
      case ContentBlockType.date:
        return _buildDateSettings();
    }
  }

  List<Widget> _buildHeaderSettings() {
    return [
      _buildTextField(
        label: 'Überschrift',
        key: 'text',
        defaultValue: 'Überschrift eingeben',
        maxLines: 2,
      ),
      const SizedBox(height: 16),
      _buildDropdown(
        label: 'Größe',
        key: 'level',
        value: _getContent('level', 1),
        items: {
          1: 'Groß (H1)',
          2: 'Mittel (H2)',
          3: 'Klein (H3)',
        },
      ),
      const SizedBox(height: 16),
      _buildAlignmentPicker('align'),
      const SizedBox(height: 16),
      _buildColorPicker('color', 'Textfarbe'),
    ];
  }

  List<Widget> _buildTextSettings() {
    return [
      _buildTextField(
        label: 'Text',
        key: 'text',
        defaultValue: 'Text eingeben...',
        maxLines: 10,
      ),
      const SizedBox(height: 16),
      _buildSlider(
        label: 'Schriftgröße',
        key: 'fontSize',
        min: 12,
        max: 24,
        value: _getContent('fontSize', 16.0),
      ),
      const SizedBox(height: 16),
      _buildAlignmentPicker('align'),
      const SizedBox(height: 16),
      _buildColorPicker('color', 'Textfarbe'),
    ];
  }

  List<Widget> _buildImageSettings() {
    final currentUrl = _getContent('url', '');

    return [
      if (currentUrl.isNotEmpty) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            currentUrl,
            height: 200,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, size: 64),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
      ElevatedButton.icon(
        onPressed: _isUploading ? null : _handleImageUpload,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.upload),
        label: Text(_isUploading ? 'Lädt hoch...' : 'Bild hochladen'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      const SizedBox(height: 16),
      _buildTextField(
        label: 'Bildunterschrift',
        key: 'caption',
        defaultValue: '',
        maxLines: 2,
      ),
    ];
  }

  List<Widget> _buildGallerySettings() {
    final List<String> images = List<String>.from(
      _getContent<List>('images', []),
    );

    return [
      // Aktuell Bilder anzeigen
      if (images.isNotEmpty) ...[
        Text(
          'Galerie (${images.length}/6)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => _removeGalleryImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],

      // Upload Button
      ElevatedButton.icon(
        onPressed: _isUploading
            ? null
            : (images.length < 6 ? _handleGalleryImagesUpload : null),
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_photo_alternate),
        label: Text(
          _isUploading
              ? 'Lädt hoch...'
              : images.length < 6
                  ? 'Bilder hinzufügen (${6 - images.length} übrig)'
                  : 'Maximum erreicht (6/6)',
        ),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          backgroundColor: images.length < 6 ? Colors.blue : Colors.grey[400],
          foregroundColor: Colors.white,
        ),
      ),

      const SizedBox(height: 16),

      _buildDropdown(
        label: 'Spalten',
        key: 'columns',
        value: _getContent('columns', 3),
        items: {
          2: '2 Spalten',
          3: '3 Spalten',
          4: '4 Spalten',
        },
      ),
    ];
  }

  List<Widget> _buildQuoteSettings() {
    return [
      _buildTextField(
        label: 'Zitat',
        key: 'text',
        defaultValue: 'Zitat eingeben...',
        maxLines: 4,
      ),
      const SizedBox(height: 16),
      _buildTextField(
        label: 'Autor',
        key: 'author',
        defaultValue: '',
      ),
      const SizedBox(height: 16),
      _buildColorPicker('color', 'Farbe'),
    ];
  }

  List<Widget> _buildDividerSettings() {
    return [
      _buildSlider(
        label: 'Dicke',
        key: 'thickness',
        min: 1,
        max: 5,
        value: _getContent('thickness', 1.0),
      ),
      const SizedBox(height: 16),
      _buildColorPicker('color', 'Farbe'),
    ];
  }

  List<Widget> _buildVideoSettings() {
    return [
      _buildTextField(
        label: 'Video-URL',
        key: 'url',
        defaultValue: '',
        hint: 'YouTube oder Vimeo Link',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        label: 'Beschreibung',
        key: 'caption',
        defaultValue: '',
        maxLines: 2,
      ),
    ];
  }

  List<Widget> _buildDateSettings() {
    return [
      _buildTextField(
        label: 'Geburtsdatum',
        key: 'birthDate',
        defaultValue: '',
        hint: 'TT.MM.JJJJ',
      ),
      const SizedBox(height: 16),
      _buildTextField(
        label: 'Sterbedatum',
        key: 'deathDate',
        defaultValue: '',
        hint: 'TT.MM.JJJJ',
      ),
    ];
  }

  Widget _buildTextField({
    required String label,
    required String key,
    required String defaultValue,
    int maxLines = 1,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _getController(key, defaultValue),
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          maxLines: maxLines,
          onChanged: (value) => _updateValue(key, value),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String key,
    required dynamic value,
    required Map<dynamic, String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          items: items.entries.map((entry) {
            return DropdownMenuItem(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _updateValue(key, newValue);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required String key,
    required double min,
    required double max,
    required double value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value.round().toString(),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: (newValue) {
            _updateValue(key, newValue);
          },
        ),
      ],
    );
  }

  Widget _buildAlignmentPicker(String key) {
    final currentAlign = _getContent(key, 'left');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ausrichtung',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildAlignButton(
                'left', Icons.format_align_left, currentAlign, key),
            const SizedBox(width: 8),
            _buildAlignButton(
                'center', Icons.format_align_center, currentAlign, key),
            const SizedBox(width: 8),
            _buildAlignButton(
                'right', Icons.format_align_right, currentAlign, key),
          ],
        ),
      ],
    );
  }

  Widget _buildAlignButton(
    String value,
    IconData icon,
    String currentAlign,
    String key,
  ) {
    final isSelected = currentAlign == value;

    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          _updateValue(key, value);
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
          side: BorderSide(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.blue : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildColorPicker(String key, String label) {
    final currentColor = _getContent(key, '#000000');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            '#000000',
            '#333333',
            '#666666',
            '#2C3E50',
            '#E74C3C',
            '#3498DB',
            '#2ECC71',
            '#F39C12',
          ].map((color) {
            return _buildColorOption(color, currentColor, key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorOption(String color, String currentColor, String key) {
    final isSelected = color == currentColor;

    return InkWell(
      onTap: () {
        _updateValue(key, color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _hexToColor(color),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    return Color(int.parse(hex, radix: 16));
  }
}
