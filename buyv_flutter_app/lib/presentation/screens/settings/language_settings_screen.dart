import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/locale_provider.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'English';
  bool _autoDetectLanguage = false;
  
  final List<Map<String, dynamic>> _languages = [
    {
      'name': 'English',
      'nativeName': 'English',
      'code': 'en',
      'flag': '🇺🇸',
      'isRTL': false,
    },
    {
      'name': 'Arabic',
      'nativeName': 'العربية',
      'code': 'ar',
      'flag': '🇸🇦',
      'isRTL': true,
    },
    {
      'name': 'Spanish',
      'nativeName': 'Español',
      'code': 'es',
      'flag': '🇪🇸',
      'isRTL': false,
    },
    {
      'name': 'French',
      'nativeName': 'Français',
      'code': 'fr',
      'flag': '🇫🇷',
      'isRTL': false,
    },
    {
      'name': 'German',
      'nativeName': 'Deutsch',
      'code': 'de',
      'flag': '🇩🇪',
      'isRTL': false,
    },
    {
      'name': 'Chinese',
      'nativeName': '中文',
      'code': 'zh',
      'flag': '🇨🇳',
      'isRTL': false,
    },
    {
      'name': 'Japanese',
      'nativeName': '日本語',
      'code': 'ja',
      'flag': '🇯🇵',
      'isRTL': false,
    },
    {
      'name': 'Korean',
      'nativeName': '한국어',
      'code': 'ko',
      'flag': '🇰🇷',
      'isRTL': false,
    },
    {
      'name': 'Portuguese',
      'nativeName': 'Português',
      'code': 'pt',
      'flag': '🇵🇹',
      'isRTL': false,
    },
    {
      'name': 'Russian',
      'nativeName': 'Русский',
      'code': 'ru',
      'flag': '🇷🇺',
      'isRTL': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF114B7F)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: const Text(
            'Language Settings',
            style: TextStyle(
              color: Color(0xFF114B7F),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Auto-detect Language Section
            Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              title: const Text(
                'Auto-detect Language',
                style: TextStyle(
                  color: const Color(0xFF114B7F),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Automatically detect language based on device settings',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              value: _autoDetectLanguage,
              onChanged: (value) {
                setState(() {
                  _autoDetectLanguage = value;
                });
              },
              activeTrackColor: const Color(0xFFFF6F00),
            ),
          ),
          
          // Current Language Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Language',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedLanguage,
                        style: const TextStyle(
                          color: const Color(0xFF114B7F),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _getLanguageFlag(_selectedLanguage),
                  style: const TextStyle(fontSize: 24),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Available Languages Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Available Languages',
                  style: TextStyle(
                    color: const Color(0xFF114B7F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_languages.length} languages',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Languages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final language = _languages[index];
                final isSelected = _selectedLanguage == language['name'];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(
                      language['flag'],
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      language['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.blue : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      language['nativeName'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : null,
                    onTap: () => _selectLanguage(language['name']),
                  ),
                );
              },
            ),
          ),
          
          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _applyLanguageChange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6F00),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Apply Changes',
                      style: TextStyle(
                        color: const Color(0xFF114B7F),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _downloadLanguagePacks,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Download Language Packs',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageFlag(String languageName) {
    final language = _languages.firstWhere(
      (lang) => lang['name'] == languageName,
      orElse: () => _languages[0],
    );
    return language['flag'];
  }

  void _selectLanguage(String languageName) {
    setState(() {
      _selectedLanguage = languageName;
    });
  }

  void _applyLanguageChange() {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    
    // Map language names to locale codes
    String languageCode = 'en';
    String countryCode = 'US';
    
    switch (_selectedLanguage) {
      case 'English':
        languageCode = 'en';
        countryCode = 'US';
        break;
      case 'Arabic':
        languageCode = 'ar';
        countryCode = 'SA';
        break;
      case 'French':
        languageCode = 'fr';
        countryCode = 'FR';
        break;
      case 'Spanish':
        languageCode = 'es';
        countryCode = 'ES';
        break;
      case 'German':
        languageCode = 'de';
        countryCode = 'DE';
        break;
      case 'Portuguese':
        languageCode = 'pt';
        countryCode = 'BR';
        break;
      case 'Chinese':
        languageCode = 'zh';
        countryCode = 'CN';
        break;
      case 'Japanese':
        languageCode = 'ja';
        countryCode = 'JP';
        break;
      case 'Korean':
        languageCode = 'ko';
        countryCode = 'KR';
        break;
      case 'Russian':
        languageCode = 'ru';
        countryCode = 'RU';
        break;
    }
    
    // Apply the language change
    localeProvider.setLocale(Locale(languageCode, countryCode));
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100],
        title: const Text(
          'Language Changed',
          style: TextStyle(color: const Color(0xFF114B7F)),
        ),
        content: Text(
          'Language has been changed to $_selectedLanguage successfully!',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to settings
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[100],
        title: const Text(
          'Restart Required',
          style: TextStyle(color: const Color(0xFF114B7F)),
        ),
        content: const Text(
          'The app needs to restart to apply the language changes. Do you want to restart now?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language will be applied on next app start'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Language changed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Restart Now'),
          ),
        ],
      ),
    );
  }

  void _downloadLanguagePacks() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[100],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Download Language Packs',
              style: TextStyle(
                color: const Color(0xFF114B7F),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Download additional language packs for offline use:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ..._languages.take(5).map((lang) => ListTile(
              leading: Text(lang['flag'], style: const TextStyle(fontSize: 20)),
              title: Text(
                lang['name'],
                style: const TextStyle(color: const Color(0xFF114B7F)),
              ),
              subtitle: Text(
                'Size: ~5MB',
                style: TextStyle(color: Colors.grey[600]),
              ),
              trailing: const Icon(Icons.download, color: Colors.blue),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading ${lang['name']} language pack...'),
                    backgroundColor: const Color(0xFFFF6F00),
                  ),
                );
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
