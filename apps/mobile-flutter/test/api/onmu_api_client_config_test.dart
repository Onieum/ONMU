import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';

void main() {
  group('ONMU API config', () {
    test('defaults to Azure staging API base URL', () {
      expect(defaultOnmuApiBaseUrl, 'https://staging-api.onmu.cloud');
    });

    test('prefers access JWT over legacy dev access token', () {
      expect(
        resolveOnmuAccessToken(
          accessJwt: 'jwt-token',
          legacyDevAccessToken: 'legacy-token',
        ),
        'jwt-token',
      );
      expect(
        resolveOnmuAccessToken(
          accessJwt: '',
          legacyDevAccessToken: 'legacy-token',
        ),
        'legacy-token',
      );
    });
  });
}
