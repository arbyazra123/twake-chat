import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:twake/blocs/workspaces_cubit/workspace_state.dart';
import 'package:twake/models/account/account.dart';
import 'package:twake/models/globals/globals.dart';
import 'package:twake/models/workspace/workspace.dart';
import 'package:twake/repositories/workspaces_repository.dart';

class WorkspacesCubit extends Cubit<WorkspaceState> {
  final WorkspacesRepository _workspacesRepository;

  WorkspacesCubit(this._workspacesRepository) : super(WorkspacesInitial());

  Future<void> fetch({String? companyId}) async {
    emit(WorkspacesLoadInProgress());
    final stream = _workspacesRepository.fetch(companyId: companyId);

    await for (var workspaces in stream) {
      Workspace? selected;
      if (Globals.instance.companyId != null) {
        selected =
            workspaces.firstWhere((c) => c.id == Globals.instance.companyId);
      }
      emit(WorkspacesLoadSuccess(workspaces: workspaces, selected: selected));
    }
  }

  Future<void> createWorkspace({
    String? companyId,
    required String name,
    List<String>? members,
  }) async {
    final workspace = await _workspacesRepository.createWorkspace(
        companyId: companyId, name: name, members: members);

    final workspaces = (state as WorkspacesLoadSuccess).workspaces;

    workspaces.add(workspace);

    emit(WorkspacesLoadSuccess(workspaces: workspaces, selected: workspace));
  }

  Future<List<Account>> fetchMembers({String? workspaceId}) async {
    final members =
        await _workspacesRepository.fetchMembers(workspaceId: workspaceId);
    return members;
  }

  void changeWorkspace({required Workspace workspace}) {
    Globals.instance.workspaceIdSet = workspace.id;

    final workspaces = (state as WorkspacesLoadSuccess).workspaces;

    emit(WorkspacesLoadSuccess(workspaces: workspaces, selected: workspace));
  }
}
