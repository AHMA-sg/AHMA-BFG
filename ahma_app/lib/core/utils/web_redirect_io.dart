import 'dart:async';
import 'dart:io';

void redirectToUrl(String url) {
  final executable = Platform.isMacOS
      ? '/usr/bin/open'
      : Platform.isWindows
      ? 'rundll32'
      : '/usr/bin/xdg-open';
  final arguments = Platform.isWindows
      ? ['url.dll,FileProtocolHandler', url]
      : [url];

  print('Opening OAuth URL: $url');
  unawaited(
    Process.run(executable, arguments)
        .then<void>((result) {
          if (result.exitCode != 0) {
            print(
              'Could not open OAuth URL (${result.exitCode}): ${result.stderr}',
            );
          }
        })
        .catchError((Object error) {
          // Keep OAuth failure visible in debug logs without crashing the app.
          // The account screen will still show the connection as incomplete.
          print('Could not open OAuth URL: $error');
        }),
  );
}
