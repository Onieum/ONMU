import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';

void main() {
  group('resolveOnmuAccessToken', () {
    test('prefers JWT define over legacy dev token', () {
      expect(
        resolveOnmuAccessToken(
          accessJwt: 'jwt-token',
          legacyDevAccessToken: 'legacy-token',
        ),
        'jwt-token',
      );
    });

    test('falls back to legacy dev token while rollout is in progress', () {
      expect(
        resolveOnmuAccessToken(
          accessJwt: '',
          legacyDevAccessToken: 'legacy-token',
        ),
        'legacy-token',
      );
    });

    test('returns empty token when no api token define is provided', () {
      expect(
        resolveOnmuAccessToken(accessJwt: '', legacyDevAccessToken: ''),
        isEmpty,
      );
    });
  });

  group('OnmuJson', () {
    test('reads ids from numeric strings', () {
      expect(OnmuJson.readInt({'id': '101'}, 'id'), 101);
      expect(OnmuJson.readInt({'id': 501}, 'id'), 501);
    });

    test('normalizes list of maps', () {
      final rows = OnmuJson.asMapList([
        {'id': '1', 'name': 'ONMU'},
      ]);

      expect(rows, hasLength(1));
      expect(rows.first['name'], 'ONMU');
    });

    test('returns safe fallbacks for missing values', () {
      expect(OnmuJson.readString({}, 'title', '약속'), '약속');
      expect(OnmuJson.readBool({}, 'closed'), false);
      expect(OnmuJson.stringList(null), isEmpty);
    });
  });
}
