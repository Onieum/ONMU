import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onmu_mobile/core/api/onmu_api_client.dart';
import 'package:onmu_mobile/features/group/repository/group_repository.dart';

void main() {
  test('API 메시지 목록 JSON을 GroupMessage로 매핑한다', () async {
    final client = _FakeOnmuApiClient(
      getResponse: {
        'messages': [
          {
            'senderName': '지민',
            'message': '안녕!',
            'timeLabel': '14:00',
            'isMine': false,
          },
          {
            'sender': 'ONMU',
            'content': '새 투표가 열렸어요.',
            'messageType': 'vote_card',
            'createdAt': '2026-06-09T14:03:00+09:00',
          },
          {'createdAt': 'not-a-date'},
        ],
      },
    );

    final messages = await ApiGroupRepository(client).fetchMessages('1');

    expect(client.lastGetPath, '/api/v1/groups/1/chat/messages');
    expect(messages, hasLength(3));
    expect(messages[0].sender, '지민');
    expect(messages[0].message, '안녕!');
    expect(messages[0].timeLabel, '14:00');
    expect(messages[0].isMine, isFalse);
    expect(messages[1].sender, 'ONMU');
    expect(messages[1].message, '새 투표가 열렸어요.');
    expect(messages[1].timeLabel, '14:03');
    expect(messages[1].isMine, isFalse);
    expect(messages[2].sender, 'ONMU');
    expect(messages[2].message, '새 활동이 있어요.');
    expect(messages[2].timeLabel, '');
  });

  test('API 메시지 작성은 POST 응답을 GroupMessage로 매핑한다', () async {
    final client = _FakeOnmuApiClient(
      postResponse: {
        'senderName': '나',
        'message': '서버로 보내요',
        'timeLabel': '방금',
        'isMine': true,
      },
    );

    final message = await ApiGroupRepository(
      client,
    ).sendMessage(groupId: '1', message: '서버로 보내요');

    expect(client.lastPostPath, '/api/v1/groups/1/chat/messages');
    expect(client.lastPostBody, {'message': '서버로 보내요'});
    expect(message.sender, '나');
    expect(message.message, '서버로 보내요');
    expect(message.timeLabel, '방금');
    expect(message.isMine, isTrue);
  });
}

class _FakeOnmuApiClient extends OnmuApiClient {
  _FakeOnmuApiClient({
    this.getResponse = const <String, dynamic>{},
    this.postResponse = const <String, dynamic>{},
  }) : super(Dio());

  final Map<String, dynamic> getResponse;
  final Map<String, dynamic> postResponse;
  String? lastGetPath;
  String? lastPostPath;
  Map<String, Object?>? lastPostBody;

  @override
  Future<Map<String, dynamic>> getObject(String path) async {
    lastGetPath = path;
    return getResponse;
  }

  @override
  Future<Map<String, dynamic>> postObject(
    String path, {
    Map<String, Object?> body = const {},
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    return postResponse;
  }
}
