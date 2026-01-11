import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LocationSettingsScreen extends StatefulWidget {
  const LocationSettingsScreen({super.key});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  bool _locationEnabled = true;
  bool _autoDetectLocation = false;
  String _selectedCountry = 'United States';
  String _selectedCity = 'New York';
  
  final List<String> _countries = [
    'United States',
    'Canada',
    'United Kingdom',
    'Germany',
    'France',
    'Australia',
    'Japan',
    'South Korea',
  ];

  final Map<String, List<String>> _cities = {
    'United States': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'],
    'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary', 'Ottawa'],
    'United Kingdom': ['London', 'Manchester', 'Birmingham', 'Liverpool', 'Leeds'],
    'Germany': ['Berlin', 'Munich', 'Hamburg', 'Cologne', 'Frankfurt'],
    'France': ['Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice'],
    'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide'],
    'Japan': ['Tokyo', 'Osaka', 'Kyoto', 'Yokohama', 'Nagoya'],
    'South Korea': ['Seoul', 'Busan', 'Incheon', 'Daegu', 'Daejeon'],
  };

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
          'Location Settings',
          style: TextStyle(
            color: Color(0xFF114B7F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Location Services Section
          _buildSectionHeader('Location Services'),
          _buildSwitchTile(
            'Enable Location Services',
            'Allow app to access your location for better experience',
            _locationEnabled,
            (value) {
              setState(() {
                _locationEnabled = value;
                if (!value) {
                  _autoDetectLocation = false;
                }
              });
            },
          ),
          const SizedBox(height: 8),
          _buildSwitchTile(
            'Auto-detect Location',
            'Automatically detect your current location',
            _autoDetectLocation,
            _locationEnabled ? (value) {
              setState(() {
                _autoDetectLocation = value;
              });
            } : null,
          ),
          
          const SizedBox(height: 24),
          
          // Manual Location Section
          _buildSectionHeader('Manual Location'),
          _buildLocationSelector(),
          
          const SizedBox(height: 24),
          
          // Current Location Section
          _buildSectionHeader('Current Location'),
          _buildCurrentLocationCard(),
          
          const SizedBox(height: 24),
          
          // Location History Section
          _buildSectionHeader('Recent Locations'),
          _buildLocationHistory(),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: const Color(0xFF114B7F),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool>? onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: onChanged != null ? Colors.white : Colors.grey[700],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: onChanged != null ? Colors.grey[700] : Colors.grey[700],
            fontSize: 14,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeTrackColor: Colors.blue,
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Country Selector
          _buildDropdown(
            'Country',
            _selectedCountry,
            _countries,
            (value) {
              setState(() {
                _selectedCountry = value!;
                _selectedCity = _cities[_selectedCountry]!.first;
              });
            },
          ),
          const SizedBox(height: 16),
          // City Selector
          _buildDropdown(
            'City',
            _selectedCity,
            _cities[_selectedCountry] ?? [],
            (value) {
              setState(() {
                _selectedCity = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
          dropdownColor: Colors.grey[200],
          style: const TextStyle(color: const Color(0xFF114B7F)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildCurrentLocationCard() {
    return Container(
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
              Icons.location_on,
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
                  '$_selectedCity, $_selectedCountry',
                  style: const TextStyle(
                    color: const Color(0xFF114B7F),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _autoDetectLocation ? 'Auto-detected' : 'Manually selected',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _getCurrentLocation,
            icon: const Icon(
              Icons.my_location,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationHistory() {
    final recentLocations = [
      'New York, United States',
      'Los Angeles, United States',
      'Toronto, Canada',
    ];

    return Column(
      children: recentLocations.map((location) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const Icon(Icons.history, color: Colors.grey),
            title: Text(
              location,
              style: const TextStyle(color: const Color(0xFF114B7F)),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            onTap: () => _selectRecentLocation(location),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6F00),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Settings',
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
            onPressed: _resetToDefault,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reset to Default',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _getCurrentLocation() {
    // Simulate getting current location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Getting current location...'),
        backgroundColor: const Color(0xFFFF6F00),
      ),
    );
  }

  void _selectRecentLocation(String location) {
    final parts = location.split(', ');
    if (parts.length >= 2) {
      setState(() {
        _selectedCity = parts[0];
        _selectedCountry = parts[1];
      });
    }
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetToDefault() {
    setState(() {
      _locationEnabled = true;
      _autoDetectLocation = false;
      _selectedCountry = 'United States';
      _selectedCity = 'New York';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to default'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
