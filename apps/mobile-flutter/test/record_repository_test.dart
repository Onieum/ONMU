import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/core/error/onmu_exception.dart';
import 'package:onmu_mobile/features/ootd/repository/record_repository.dart';

void main() {
  test('uploadMedia reports missing storageKey as contract mismatch', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://dev-api.onmu.cloud'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              data: {'publicUrl': '/api/v1/media/public?key=photo.jpg'},
            ),
          );
        },
      ),
    );
    final repository = ApiRecordRepository(OnmuApiClient(dio));

    await expectLater(
      repository.uploadMedia(Uint8List.fromList([1, 2, 3]), 'photo.jpg'),
      throwsA(
        isA<OnmuContractException>()
            .having(
              (error) => error.kind,
              'kind',
              OnmuErrorKind.contractMismatch,
            )
            .having((error) => error.reportable, 'reportable', isTrue),
      ),
    );
  });
}
