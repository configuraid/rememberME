import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service für das native iOS 26 Onboarding via MethodChannel.
/// Auf Android wird das Onboarding übersprungen (oder du baust
/// hier eine Flutter-basierte Alternative ein).
class NativeOnboardingService {
  static const _channel = MethodChannel('com.rememberme/onboarding');
  static const _prefKey = 'onboarding_completed';

  /// Prüft ob Onboarding bereits abgeschlossen wurde
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Zeigt das native iOS Onboarding an (nur iOS).
  /// Gibt `true` zurück wenn abgeschlossen, `false` bei Fehler/Skip.
  static Future<bool> showOnboardingIfNeeded() async {
    // Bereits abgeschlossen? → Überspringen
    if (await isOnboardingCompleted()) {
      debugPrint('✅ Onboarding bereits abgeschlossen');
      return true;
    }

    // Nur auf iOS das native Onboarding zeigen
    if (!Platform.isIOS) {
      debugPrint('📱 Kein iOS – Onboarding übersprungen');
      // TODO: Hier ggf. Flutter-basiertes Onboarding für Android einbauen
      await _markCompleted();
      return true;
    }

    try {
      debugPrint('🚀 Starte natives iOS Onboarding...');
      final result = await _channel.invokeMethod('showOnboarding');

      if (result == true) {
        await _markCompleted();
        debugPrint('✅ Natives Onboarding abgeschlossen');
        return true;
      }

      return false;
    } on PlatformException catch (e) {
      debugPrint('❌ Onboarding Fehler: ${e.message}');
      // Bei Fehler trotzdem weitermachen, nicht blockieren
      await _markCompleted();
      return true;
    } on MissingPluginException {
      // MethodChannel nicht registriert (z.B. im Debug/Simulator)
      debugPrint('⚠️ Onboarding MethodChannel nicht verfügbar');
      await _markCompleted();
      return true;
    }
  }

  /// Markiert Onboarding als abgeschlossen
  static Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// Setzt den Onboarding-Status zurück (z.B. für Debug/Testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
    debugPrint('🔄 Onboarding zurückgesetzt');
  }
}
