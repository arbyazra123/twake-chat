import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import 'package:twake/blocs/channels_cubit/add_channel_cubit/add_channel_state.dart';
import 'package:twake/blocs/channels_cubit/channels_cubit.dart';
import 'package:twake/models/account/account.dart';
import 'package:twake/models/channel/channel_role.dart';
import 'package:twake/models/globals/globals.dart';
import 'package:twake/repositories/channels_repository.dart';
import 'package:twake/utils/emojis.dart';

class AddChannelCubit extends Cubit<AddChannelState> {
  late final ChannelsRepository _channelsRepository;
  late final ChannelsCubit _channelsCubit;

  void setChannelVisibility(ChannelVisibility channelVisibility) {
    emit(AddChannelValidation(
      validToCreateChannel: state.validToCreateChannel,
      showEmoijKeyboard: state.showEmoijKeyboard,
      emoijIcon: state.emoijIcon,
      channelVisibility: channelVisibility,
      selectedMembers: state.selectedMembers,
    ));
  }

  AddChannelCubit({
    required ChannelsRepository channelsRepository,
    required ChannelsCubit channelsCubit,
  }) : super(AddChannelInitial()) {
    _channelsRepository = channelsRepository;
    _channelsCubit = channelsCubit;
  }

  void showEmoijKeyBoard(bool isShow) {
    emit(AddChannelValidation(
        validToCreateChannel: state.validToCreateChannel,
        showEmoijKeyboard: isShow,
        emoijIcon: state.emoijIcon,
        channelVisibility: state.channelVisibility,
        selectedMembers: state.selectedMembers));
  }

  void setEmoijIcon(String icon) {
    emit(AddChannelValidation(
        validToCreateChannel: state.validToCreateChannel,
        showEmoijKeyboard: false,
        emoijIcon: icon,
        channelVisibility: state.channelVisibility,
        selectedMembers: state.selectedMembers));
  }

  void validateAddChannelData({required String name}) {
    emit(AddChannelValidation(
        validToCreateChannel: name.isNotEmpty,
        showEmoijKeyboard: state.showEmoijKeyboard,
        emoijIcon: state.emoijIcon,
        channelVisibility: state.channelVisibility,
        selectedMembers: state.selectedMembers));
  }

  Future<void> create({
    required String name,
    String? description,
    bool isDefault = false,
  }) async {
    emit(AddChannelInProgress(
      emoijIcon: state.emoijIcon,
      channelVisibility: state.channelVisibility,
      selectedMembers: state.selectedMembers,
    ));

    final now = DateTime.now().millisecondsSinceEpoch;
    var channel = Channel(
      id: now.toString(),
      name: name,
      icon: state.emoijIcon.isEmpty ? Emojis.randomEmoij() : state.emoijIcon,
      description: description,
      companyId: Globals.instance.companyId!,
      workspaceId: Globals.instance.workspaceId!,
      members: state.selectedMembers.map((member) => member.id).toList(),
      membersCount: state.selectedMembers.length,
      lastActivity: now,
      visibility: state.channelVisibility,
      role: ChannelRole.owner,
    );
    try {
      channel = await _channelsRepository.create(
        channel: channel,
        isDefault: isDefault,
      );
    } catch (e) {
      Logger().e('Error occured during channel creation:\n$e');
      emit(AddChannelFailure());
      return;
    }

    emit(AddChannelSuccess());
    _channelsCubit.changeSelectedChannelAfterCreateSuccess(channel: channel);
  }

  void addSelectedMembers(List<Account> members) {
    emit(AddChannelValidation(
        validToCreateChannel: state.validToCreateChannel,
        showEmoijKeyboard: state.showEmoijKeyboard,
        emoijIcon: state.emoijIcon,
        channelVisibility: state.channelVisibility,
        selectedMembers: members));
  }

  void removeSelectedMember(Account member) {
    List<Account> members = List.from(state.selectedMembers);
    members.removeWhere((element) => element.id == member.id);

    emit(AddChannelValidation(
        validToCreateChannel: state.validToCreateChannel,
        showEmoijKeyboard: state.showEmoijKeyboard,
        emoijIcon: state.emoijIcon,
        channelVisibility: state.channelVisibility,
        selectedMembers: members));
  }
}
