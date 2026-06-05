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

class GroupMemoryBoardViewModel
    extends FamilyAsyncNotifier<GroupMemoryBoardState, String> {
  @override
  Future<GroupMemoryBoardState> build(String arg) async {
    final repository = ref.watch(groupRepositoryProvider);
    final group = await repository.fetchGroup(arg);
    final memories = await repository.fetchMemories(arg);

    return GroupMemoryBoardState(group: group, memories: memories);
  }
}

class GroupMemoryDetailViewModel
    extends FamilyAsyncNotifier<GroupMemoryDetailState, GroupMemoryScope> {
  @override
  Future<GroupMemoryDetailState> build(GroupMemoryScope arg) async {
    final repository = ref.watch(groupRepositoryProvider);
    final memories = await repository.fetchMemories(arg.groupId);
    final memoryIndex = memories.indexWhere(
      (memory) => memory.id.toString() == arg.memoryId,
    );
    final safeIndex = memoryIndex < 0 ? 0 : memoryIndex;

    return GroupMemoryDetailState(
      memory: memories[safeIndex],
      photoIndex: safeIndex,
    );
  }
}
