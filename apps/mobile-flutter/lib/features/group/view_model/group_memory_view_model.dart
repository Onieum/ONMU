import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/group_models.dart';
import '../repository/group_repository.dart';

typedef GroupMemoryScope = ({String groupId, String memoryId});

final groupMemoryBoardViewModelProvider =
    AsyncNotifierProvider.family<
      GroupMemoryBoardViewModel,
      GroupMemoryBoardState,
      String
    >(GroupMemoryBoardViewModel.new);

final groupMemoryDetailViewModelProvider =
    AsyncNotifierProvider.family<
      GroupMemoryDetailViewModel,
      GroupMemoryDetailState,
      GroupMemoryScope
    >(GroupMemoryDetailViewModel.new);

class GroupMemoryBoardState {
  const GroupMemoryBoardState({required this.group, required this.memories});

  final GroupSummary group;
  final List<GroupMemoryRecord> memories;
}

class GroupMemoryDetailState {
  const GroupMemoryDetailState({
    required this.memory,
    required this.photoIndex,
  });

  final GroupMemoryRecord memory;
  final int photoIndex;
}

class GroupMemoryBoardViewModel extends AsyncNotifier<GroupMemoryBoardState> {
  GroupMemoryBoardViewModel(this.groupId);

  final String groupId;

  @override
  Future<GroupMemoryBoardState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(groupId);
    final memories = await repository.fetchMemories(groupId);

    return GroupMemoryBoardState(group: group, memories: memories);
  }
}

class GroupMemoryDetailViewModel extends AsyncNotifier<GroupMemoryDetailState> {
  GroupMemoryDetailViewModel(this.scope);

  final GroupMemoryScope scope;

  @override
  Future<GroupMemoryDetailState> build() async {
    final repository = ref.watch(groupRepositoryProvider);
    final memory = await _fetchMemory(repository);

    return GroupMemoryDetailState(memory: memory, photoIndex: memory.id);
  }

  Future<GroupMemoryRecord> _fetchMemory(GroupRepository repository) async {
    try {
      return await repository.fetchMemory(
        groupId: scope.groupId,
        memoryId: scope.memoryId,
      );
    } catch (error, stackTrace) {
      final memories = await repository.fetchMemories(scope.groupId);
      final parsedId = int.tryParse(scope.memoryId);
      for (final memory in memories) {
        if (memory.id == parsedId || memory.id.toString() == scope.memoryId) {
          return memory;
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
