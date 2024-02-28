import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyLoginPage(),
    );
  }
}

class MyLoginPage extends StatefulWidget {
  @override
  _MyLoginPageState createState() => _MyLoginPageState();
}

class _MyLoginPageState extends State<MyLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  Map<String, dynamic> _deviceData = <String, dynamic>{};
  String? accessToken;
  String? idSession;
  String? systemO;
  String? version;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Text('ETECSA Login')),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleLogin,
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: accessToken != null ? _handleLogout : null,
              child: Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }

//!servicios

  Future<Map<String, dynamic>> initPlataformsState() async {
    var deviceData = <String, dynamic>{};
    try {
      if (Platform.isAndroid) {
        deviceData = _readAndroidBuildData(await deviceInfo.androidInfo);
      } else if (Platform.isIOS) {
        deviceData = _readIosDeviceInfo(await deviceInfo.iosInfo);
      }
    } on PlatformException {
      deviceData = <String, dynamic>{'error': 'failed to get platform version'};
    }
    if (!mounted) {}
    setState(() {
      _deviceData = deviceData;
    });
    return deviceData;
  }

  Future<Map<String, dynamic>> login(
      String username, String password, String sistema, String version) async {
    var response = await http.post(
      Uri.parse(
          'http://172.28.191.13/realms/etecsa-np/protocol/openid-connect/token'),
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mobile  ($sistema $version)',
      },
      body: {
        'client_id': 'flutter-demo',
        'username': username,
        'password': password,
        'grant_type': 'password',
        'client_secret': 'mMWlKEKVwzfM9jOCEEyB2jVz2rNspSfm',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to login');
    }
  }

  Future<void> logout(String idSession, String accessToken) async {
    if (accessToken != null) {
      var response = await http.delete(
        Uri.parse(
            'http://172.28.191.13/realms/etecsa-np/account/sessions/$idSession'),
        headers: <String, String>{
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 204) {
        print('Logout successful');
        print(response.statusCode);
        setState(() {});
        _showLogoutSuccessMessage();
      } else if (response.statusCode == 401) {
        print('Unauthorized');
      } else {
        print(response.statusCode);
      }
    }
  }

  //!servicios------------------------------------------------------------------

  //todo------------------------------------------------------------------------

  //?funciones------------------------------------------------------------------

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release, //!
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'displaySizeInches':
          ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
      'displayWidthPixels': build.displayMetrics.widthPx,
      'displayWidthInches': build.displayMetrics.widthInches,
      'displayHeightPixels': build.displayMetrics.heightPx,
      'displayHeightInches': build.displayMetrics.heightInches,
      'displayXDpi': build.displayMetrics.xDpi,
      'displayYDpi': build.displayMetrics.yDpi,
      'serialNumber': build.serialNumber,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion, //!
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  void _handleLogin() {
    String username = _usernameController.text;
    String password = _passwordController.text;
    try {
      initPlataformsState().then((data) {
        if (Platform.operatingSystem == 'android') {
          systemO = 'Android';
          version = data["version.release"];
        } else if (Platform.operatingSystem == 'iPhone') {
          systemO = 'iPhone';
          version = data["systemVersion"];
        } else {
          print('failed device');
        }
        print(systemO);
        print(version);
      });
      login(username, password, systemO!, version!).then((response) => {
            accessToken = response['access_token'],
            idSession = response['session_state'],
            setState(() {}),
            _showLoginSuccessMessage(),
          });
    } catch (e) {
      print('Login failed: $e');
    }
  }

  void _handleLogout() {
    print("token logout");
    print(accessToken);
    print(idSession);
    logout(idSession!, accessToken!);
    setState(() {});
  }

  void _showLoginSuccessMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Successful'),
          content: Text('You have been logged in successfully.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLogoutSuccessMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout Successful'),
          content: Text('You have been logged out.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
