import 'dart:io';

class WindowsProtocolRegistration {
  static const String scheme = 'geoevent';

  static Future<void> ensureRegistered() async {
    if (!Platform.isWindows) return;

    final exePath = Platform.resolvedExecutable;
    final appDir = File(exePath).parent.path;
    final appExePath = '$appDir\\geo_event_desktop.exe';
    final effectiveExePath =
        File(appExePath).existsSync() ? appExePath : exePath;

    final escapedExe = effectiveExePath.replaceAll('"', '\\"');

    final script = r'''
$scheme = "geoevent"
$exe = "__EXE_PATH__"

New-Item -Path "HKCU:\Software\Classes\$scheme" -Force | Out-Null
Set-Item -Path "HKCU:\Software\Classes\$scheme" -Value "URL:GeoEvent Protocol"
New-ItemProperty -Path "HKCU:\Software\Classes\$scheme" -Name "URL Protocol" -Value "" -PropertyType String -Force | Out-Null

New-Item -Path "HKCU:\Software\Classes\$scheme\DefaultIcon" -Force | Out-Null
Set-Item -Path "HKCU:\Software\Classes\$scheme\DefaultIcon" -Value ('"' + $exe + '",0')

New-Item -Path "HKCU:\Software\Classes\$scheme\shell\open\command" -Force | Out-Null
Set-Item -Path "HKCU:\Software\Classes\$scheme\shell\open\command" -Value ('"' + $exe + '" "%1"')
'''
        .replaceAll('__EXE_PATH__', escapedExe);

    final result = await Process.run(
      'powershell',
      ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', script],
    );

    if (result.exitCode != 0) {
      throw Exception(
        'Failed to register Windows protocol handler: ${result.stderr}',
      );
    }
  }
}