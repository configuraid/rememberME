import 'package:equatable/equatable.dart';

enum LicenseType { basic, lifetime }

class LicenseModel extends Equatable {
  final String id;
  final String userId;
  final LicenseType type;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final double storageLimit; // in GB
  final double storageUsed; // in GB
  final int maxImages;
  final int maxVideos;
  final int maxMemorials;
  final bool canUseAdvancedLayouts;
  final bool canInviteMembers;
  final bool canUseCustomDomain;
  final List<String> availableContentBlocks;

  const LicenseModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.purchaseDate,
    this.expiryDate,
    required this.storageLimit,
    this.storageUsed = 0.0,
    required this.maxImages,
    required this.maxVideos,
    required this.maxMemorials,
    required this.canUseAdvancedLayouts,
    required this.canInviteMembers,
    required this.canUseCustomDomain,
    required this.availableContentBlocks,
  });

  // Factory für Basis-Lizenz
  factory LicenseModel.basic({
    required String id,
    required String userId,
  }) {
    return LicenseModel(
      id: id,
      userId: userId,
      type: LicenseType.basic,
      purchaseDate: DateTime.now(),
      storageLimit: 0.5, // 500 MB
      storageUsed: 0.0,
      maxImages: 20,
      maxVideos: 0,
      maxMemorials: 1,
      canUseAdvancedLayouts: false,
      canInviteMembers: false,
      canUseCustomDomain: false,
      availableContentBlocks: const [
        'hero_section',
        'text_block',
        'image_gallery',
        'quote_section',
      ],
    );
  }

  // Factory für Lifetime-Lizenz
  factory LicenseModel.lifetime({
    required String id,
    required String userId,
  }) {
    return LicenseModel(
      id: id,
      userId: userId,
      type: LicenseType.lifetime,
      purchaseDate: DateTime.now(),
      storageLimit: 10.0, // 10 GB
      storageUsed: 0.0,
      maxImages: -1, // Unlimited
      maxVideos: -1, // Unlimited
      maxMemorials: -1, // Unlimited
      canUseAdvancedLayouts: true,
      canInviteMembers: true,
      canUseCustomDomain: true,
      availableContentBlocks: const [
        'hero_section',
        'text_block',
        'image_gallery',
        'quote_section',
        'video_collage',
        'audio_player',
        'timeline',
        'guestbook',
        'memory_map',
        'photo_gallery_3d',
      ],
    );
  }

  // Getter für Prozent des genutzten Speichers
  double get storageUsedPercentage {
    if (storageLimit == 0) return 0;
    return (storageUsed / storageLimit) * 100;
  }

  // Getter für verbleibenden Speicher
  double get storageRemaining => storageLimit - storageUsed;

  // Prüfen ob Speicher-Limit erreicht
  bool get isStorageFull => storageUsed >= storageLimit;

  // Prüfen ob Content-Block verfügbar ist
  bool hasContentBlock(String blockType) {
    return availableContentBlocks.contains(blockType);
  }

  // CopyWith Methode
  LicenseModel copyWith({
    String? id,
    String? userId,
    LicenseType? type,
    DateTime? purchaseDate,
    DateTime? expiryDate,
    double? storageLimit,
    double? storageUsed,
    int? maxImages,
    int? maxVideos,
    int? maxMemorials,
    bool? canUseAdvancedLayouts,
    bool? canInviteMembers,
    bool? canUseCustomDomain,
    List<String>? availableContentBlocks,
  }) {
    return LicenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expiryDate: expiryDate ?? this.expiryDate,
      storageLimit: storageLimit ?? this.storageLimit,
      storageUsed: storageUsed ?? this.storageUsed,
      maxImages: maxImages ?? this.maxImages,
      maxVideos: maxVideos ?? this.maxVideos,
      maxMemorials: maxMemorials ?? this.maxMemorials,
      canUseAdvancedLayouts:
          canUseAdvancedLayouts ?? this.canUseAdvancedLayouts,
      canInviteMembers: canInviteMembers ?? this.canInviteMembers,
      canUseCustomDomain: canUseCustomDomain ?? this.canUseCustomDomain,
      availableContentBlocks:
          availableContentBlocks ?? this.availableContentBlocks,
    );
  }

  // ToJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'purchaseDate': purchaseDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'storageLimit': storageLimit,
      'storageUsed': storageUsed,
      'maxImages': maxImages,
      'maxVideos': maxVideos,
      'maxMemorials': maxMemorials,
      'canUseAdvancedLayouts': canUseAdvancedLayouts,
      'canInviteMembers': canInviteMembers,
      'canUseCustomDomain': canUseCustomDomain,
      'availableContentBlocks': availableContentBlocks,
    };
  }

  // FromJson
  factory LicenseModel.fromJson(Map<String, dynamic> json) {
    return LicenseModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: LicenseType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
      storageLimit: (json['storageLimit'] as num).toDouble(),
      storageUsed: (json['storageUsed'] as num).toDouble(),
      maxImages: json['maxImages'] as int,
      maxVideos: json['maxVideos'] as int,
      maxMemorials: json['maxMemorials'] as int,
      canUseAdvancedLayouts: json['canUseAdvancedLayouts'] as bool,
      canInviteMembers: json['canInviteMembers'] as bool,
      canUseCustomDomain: json['canUseCustomDomain'] as bool,
      availableContentBlocks:
          List<String>.from(json['availableContentBlocks'] as List),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        purchaseDate,
        expiryDate,
        storageLimit,
        storageUsed,
        maxImages,
        maxVideos,
        maxMemorials,
        canUseAdvancedLayouts,
        canInviteMembers,
        canUseCustomDomain,
        availableContentBlocks,
      ];
}
