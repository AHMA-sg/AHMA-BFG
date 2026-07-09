export 'web_redirect_stub.dart'
    if (dart.library.html) 'web_redirect_web.dart'
    if (dart.library.io) 'web_redirect_io.dart';
