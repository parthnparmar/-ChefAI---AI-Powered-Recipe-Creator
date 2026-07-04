import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../l10n/app_localizations.dart';

class LanguageProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  String _currentLanguage = 'en';
  
  String get currentLanguage => _currentLanguage;

  void loadLanguage() {
    _currentLanguage = _storageService.selectedLanguage;
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      await _storageService.setSelectedLanguage(languageCode);
      notifyListeners();
    }
  }

  String translate(String key) {
    return AppLocalizations.translate(key, _currentLanguage);
  }
}