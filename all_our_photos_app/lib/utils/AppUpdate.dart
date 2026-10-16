/*
  Purpose: Force the installed web app / PWA to pick up a newly deployed build.

  Chrome only re-checks the service worker about once a day, and the browser
  HTTP cache can also serve old bootstrap files, so a plain reload can keep
  showing the old version. This unregisters service workers, empties the Cache
  Storage, refetches the key files bypassing the HTTP cache, then reloads.
*/
import 'dart:js_interop';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

const _bootFiles = ['./', 'flutter_bootstrap.js', 'main.dart.js'];

/// Returns false (and does nothing) when not running as a web app.
Future<bool> forceAppUpdate() async {
  if (!kIsWeb) return false;
  try {
    final regs = await web.window.navigator.serviceWorker
        .getRegistrations()
        .toDart;
    for (final reg in regs.toDart) {
      await reg.unregister().toDart;
    }
  } catch (_) {} // no service worker support is fine
  try {
    final names = await web.window.caches.keys().toDart;
    for (final name in names.toDart) {
      await web.window.caches.delete(name.toDart).toDart;
    }
  } catch (_) {}
  for (final file in _bootFiles) {
    try {
      await web.window
          .fetch(file.toJS, web.RequestInit(cache: 'reload'))
          .toDart;
    } catch (_) {} // best effort; the reload below still happens
  }
  web.window.location.reload();
  return true;
}
