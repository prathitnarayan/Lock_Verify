import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LocalAuthentication auth = LocalAuthentication();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool _isPasskeyEnabled = false;
  bool _isLoading = true;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _checkPasskeyState();
  }

  Future<void> _checkPasskeyState() async {
    try {
      final value = await secureStorage.read(key: 'passkey_enabled');
      setState(() {
        _isPasskeyEnabled = value == 'true';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error reading from storage: $e');
      setState(() {
        _isPasskeyEnabled = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePasskeyAccess() async {
    if (_isToggling) return;

    setState(() => _isToggling = true);

    try {
      final isSupported = await auth.isDeviceSupported();
      final hasBiometrics = await auth.canCheckBiometrics;
      final biometrics = await auth.getAvailableBiometrics();

      if (!isSupported || !hasBiometrics || biometrics.isEmpty) {
        _showSnackbar("Biometric authentication is not available");
        return;
      }

      final authResult = await auth.authenticate(
        localizedReason: _isPasskeyEnabled
            ? 'Authenticate to disable app lock'
            : 'Authenticate to enable app lock',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      if (authResult) {
        final updatedValue = (!_isPasskeyEnabled).toString();
        await secureStorage.write(key: 'passkey_enabled', value: updatedValue);

        setState(() => _isPasskeyEnabled = !_isPasskeyEnabled);

        _showSnackbar(
          _isPasskeyEnabled
              ? 'App Lock has been enabled'
              : 'App Lock has been disabled',
        );
      } else {
        _showSnackbar("Authentication failed or cancelled");
      }
    } catch (e) {
      debugPrint('Auth toggle error: $e');
      _showSnackbar("Error during authentication");
    } finally {
      setState(() => _isToggling = false);
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blue[900],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                ListTile(
                  leading: Icon(
                    _isPasskeyEnabled ? Icons.lock : Icons.lock_open,
                    color: _isPasskeyEnabled ? Colors.green : Colors.grey,
                  ),
                  title: Text(
                    _isPasskeyEnabled ? 'Disable App Lock' : 'Enable App Lock',
                  ),
                  subtitle: Text(
                    _isPasskeyEnabled
                        ? 'App lock is currently enabled'
                        : 'App lock is currently disabled',
                  ),
                  trailing: IgnorePointer(
                    ignoring: _isToggling,
                    child: Switch(
                      value: _isPasskeyEnabled,
                      onChanged: (_) => _togglePasskeyAccess(),
                    ),
                  ),
                  onTap: _togglePasskeyAccess,
                ),
                const Divider(),
                // Future items like: Export Keys, Reset App, About, etc.
              ],
            ),
    );
  }
}
