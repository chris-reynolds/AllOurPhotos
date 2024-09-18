// import 'package:aopmodel/aopmodel.dart';
import 'package:test/test.dart';
import 'test_config.dart';
import 'package:aopcommon/aopcommon.dart' show log, WebFile;

String rootUrl = '';

Future<void> initConfig() async {
  await config.load('aop_testconfig.json');
  log.message('loaded config $config');
} // of initConfig

void main() {
  group('Test Album Fetch', () {
    print('Test album fetch');

    setUp(() async {
      await initConfig();
      rootUrl = 'http://${config['host']}:${config['port']}/';
      WebFile.setRootUrl(rootUrl);
    });

    test('dev web connect', () async {
      bool hasServer = await WebFile.hasWebServer;
      assert(hasServer, 'no webserver connection');
    });
    test('Dev database connect', () async {
      //   expect(awesome.isAwesome, isTrue);
    });
  });
}
