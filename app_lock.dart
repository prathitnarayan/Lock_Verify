import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppLockWrapper extends StatefulWidget {
  final Widget child;

  const AppLockWrapper({super.key, required this.child});

  @override
  State<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends State<AppLockWrapper>
    with WidgetsBindingObserver {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final LocalAuthentication _auth = LocalAuthentication();

  bool _authenticated = false;
  bool _appLockEnabled = false;
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLockStatus();
  }

  Future<void> _loadLockStatus() async {
    final status = await _storage.read(key: 'passkey_enabled');
    final isEnabled = status == 'true';
    setState(() {
      _appLockEnabled = isEnabled;
    });

    if (_appLockEnabled) {
      await _authenticate();
    } else {
      setState(() => _authenticated = true);
    }
  }

  Future<void> _authenticate() async {
    if (_authInProgress) return;
    _authInProgress = true;

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (mounted) {
        setState(() {
          _authenticated = didAuthenticate;
        });
      }
    } on PlatformException catch (e) {
      debugPrint('[AppLock] Authentication failed: $e');
      setState(() => _authenticated = false);
    } finally {
      _authInProgress = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_appLockEnabled) return;

    if (state == AppLifecycleState.resumed) {
      if (!_authenticated) {
        _authenticate();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _authenticated = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_appLockEnabled && !_authenticated) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }
    return widget.child;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
