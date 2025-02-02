import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:twake/blocs/camera_cubit/camera_cubit.dart';
import 'package:twake/blocs/file_cubit/file_transition_cubit.dart';
import 'package:twake/blocs/file_cubit/upload/file_upload_cubit.dart';
import 'package:twake/blocs/gallery_cubit/gallery_cubit.dart';
import 'package:twake/blocs/mentions_cubit/mentions_cubit.dart';
import 'package:twake/config/image_path.dart';
import 'package:twake/pages/chat/gallery/gallery_view.dart';
import 'package:twake/utils/constants.dart';
import 'package:twake/utils/extensions.dart';
import 'package:twake/utils/utilities.dart';
import 'package:twake/widgets/common/link_content_preview_input.dart';
import 'package:twake/widgets/common/twake_alert_dialog.dart';
import 'package:twake/widgets/sheets/mention_sheet.dart';

class ComposeBar extends StatefulWidget {
  final bool autofocus;
  final Function(String, BuildContext) onMessageSend;
  final Function(String, BuildContext) onTextUpdated;
  final String? initialText;

  ComposeBar({
    Key? key,
    required this.onMessageSend,
    required this.onTextUpdated,
    this.autofocus = false,
    this.initialText = '',
  }) : super(key: key);

  @override
  _ComposeBar createState() => _ComposeBar();
}

class _ComposeBar extends State<ComposeBar> {
  final _userMentionRegex = RegExp(r'(^|\s)@[A-Za-z0-9._-]+$');
  bool _emojiVisible = false;
  bool _forceLooseFocus = false;
  bool _canSend = false;

  final _focusNode = FocusNode();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    if (widget.initialText?.isNotReallyEmpty ?? false) {
      _controller.text = widget.initialText!; // possibly retrieved from cache.
      setState(() {
        _canSend = true;
      });
    }

    _focusNode.addListener(() {
      if (_focusNode.hasPrimaryFocus)
        setState(() {
          _emojiVisible = false;
        });
    });

    _controller.addListener(() {
      if (_controller.selection.base.offset < 0) return;
      String text = _controller.text;
      text = text.substring(0, _controller.selection.base.offset);
      if (_userMentionRegex.hasMatch(text)) {
        Get.find<MentionsCubit>().fetch(
          searchTerm: text.split('@').last.trimRight(),
        );
      }
      // Update for cache handlers
      widget.onTextUpdated(text, context);

      // Set Send button state by combination of checking text and file uploading
      _setSendButtonState(
          stateWithoutFileUploading: _controller.text.isNotReallyEmpty);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ComposeBar oldWidget) {
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText ?? '';
    }
    // print('FORCE LOOSE FOCUS: $_forceLooseFocus');
    if (widget.autofocus && !_forceLooseFocus) {
      _focusNode.requestFocus();
    }
    super.didUpdateWidget(oldWidget);
  }

  void toggleEmojiBoard() async {
    if (_focusNode.hasPrimaryFocus) {
      _focusNode.unfocus();
      _forceLooseFocus = true;
    }
    setState(() {
      _emojiVisible = !_emojiVisible;
    });
    if (!_emojiVisible) {
      _forceLooseFocus = false;
      _focusNode.requestFocus();
    }
  }

  void mentionReplace(String username) async {
    String text = _controller.text;
    text = text.substring(0, _controller.selection.base.offset);
    _controller.text = _controller.text.replaceRange(
      text.lastIndexOf('@'),
      _controller.selection.base.offset,
      '@$username ',
    );
    _controller.selection = TextSelection.fromPosition(
      TextPosition(
        offset: text.lastIndexOf('@') + username.length + 2,
      ),
    );
  }

  Future<bool> onBackPress() async {
    if (_emojiVisible) {
      setState(() {
        _emojiVisible = false;
      });
    } else {
      Navigator.pop(context);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      LinkContentPreviewInput(controller: _controller),
      WillPopScope(
        onWillPop: onBackPress,
        child: Column(
          children: [
            MentionSheet(onTapMention: mentionReplace),
            TextInput(
              controller: _controller,
              scrollController: _scrollController,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              toggleEmojiBoard: toggleEmojiBoard,
              emojiVisible: _emojiVisible,
              onMessageSend: widget.onMessageSend,
              canSend: _canSend,
            ),
            Offstage(
              offstage: !_emojiVisible,
              child: Container(
                height: 250,
                child: EmojiPicker(
                  onEmojiSelected: (cat, emoji) {
                    _controller.text += emoji.emoji;
                    _setSendButtonState(stateWithoutFileUploading: true);
                  },
                  config: Config(
                    bottomActionBarConfig: BottomActionBarConfig(
                      // showRecentsTab: true,
                      // noRecentsText: AppLocalizations.of(context)!.noRecents,
                      // noRecentsStyle: Theme.of(context)
                      //     .textTheme
                      //     .headline3!
                      //     .copyWith(fontSize: 20),
                      // bgColor: Theme.of(context).colorScheme.secondaryContainer,
                      // progressIndicatorColor:
                      //     Theme.of(context).colorScheme.surface,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      indicatorColor: Theme.of(context).colorScheme.surface,
                      iconColor: Theme.of(context).colorScheme.secondary,
                      iconColorSelected: Theme.of(context).colorScheme.surface,
                      initCategory: Category.RECENT,
                      categoryIcons: const CategoryIcons(),
                    ),
                    emojiViewConfig: EmojiViewConfig(
                      columns: 7,
                      emojiSizeMax: 32.0,
                      verticalSpacing: 0,
                      horizontalSpacing: 0,
                      recentsLimit: 28,
                      buttonMode: ButtonMode.MATERIAL,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    ]);
  }

  void _setSendButtonState({bool stateWithoutFileUploading = false}) {
    setState(() {
      _canSend = stateWithoutFileUploading;
    });
  }
}

class TextInput extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final Function? toggleEmojiBoard;
  final bool? autofocus;
  final bool? emojiVisible;
  final bool canSend;
  final Function onMessageSend;

  TextInput({
    required this.onMessageSend,
    this.controller,
    this.focusNode,
    this.autofocus,
    this.emojiVisible,
    this.scrollController,
    this.toggleEmojiBoard,
    this.canSend = false,
  });

  @override
  _TextInputState createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: 11.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _buildAttachment(),
          ),
          Expanded(
            child: _buildMessageContent(),
          ),
          _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildAttachment() {
    return IconButton(
      constraints: const BoxConstraints(
        maxHeight: 24.0,
        maxWidth: 24.0,
      ),
      padding: EdgeInsets.zero,
      icon: Image.asset(imageAddFile),
      onPressed: () => _handleOpenGallery(),
      color: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildMessageContent() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          _buildMessageTextField(),
          GestureDetector(
            onTap: widget.toggleEmojiBoard as void Function()?,
            child: Padding(
              padding: const EdgeInsets.only(right: 4, left: 4, bottom: 4),
              child: Image.asset(imageEmojiIcon, width: 24, height: 24),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMessageTextField() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(17),
      child: _buildTextField(),
    );
  }

  Widget _buildTextField() {
    return SizedBox(
      height: widget.controller!.text.isNotEmpty ? null : 38,
      child: TextField(
        style: Theme.of(context)
            .textTheme
            .headline1!
            .copyWith(fontSize: 17, fontWeight: FontWeight.w400),
        maxLines: 4,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        autofocus: widget.autofocus!,
        focusNode: widget.focusNode,
        scrollController: widget.scrollController,
        controller: widget.controller,
        keyboardAppearance: Theme.of(context).colorScheme.brightness,
        toolbarOptions:
            ToolbarOptions(copy: true, paste: true, cut: true, selectAll: true),
        decoration: InputDecoration(
          filled: true,
          fillColor: Theme.of(context).colorScheme.secondaryContainer,
          contentPadding:
              const EdgeInsets.only(left: 12, right: 25, top: 4, bottom: 4),
          hintText: AppLocalizations.of(context)!.newReply,
          hintStyle: Theme.of(context)
              .textTheme
              .headline2!
              .copyWith(fontSize: 17, fontWeight: FontWeight.w500),
          border: const OutlineInputBorder(
            borderSide: BorderSide(
              style: BorderStyle.none,
            ),
          ),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              style: BorderStyle.none,
            ),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(
              style: BorderStyle.none,
            ),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.canSend
            ? () async {
                widget.onMessageSend(
                  await Get.find<MentionsCubit>()
                      .completeMentions(widget.controller!.text),
                  context,
                );
                widget.controller!.clear();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 36,
            width: 36,
            child: widget.canSend
                ? Get.isDarkMode
                    ? Image.asset(
                        imageSendBlue,
                        color: Theme.of(context).colorScheme.onSurface,
                      )
                    : Image.asset(
                        imageSendBlue,
                      )
                : Get.isDarkMode
                    ? Image.asset(
                        imageSend,
                        color: Theme.of(context).colorScheme.secondaryContainer,
                      )
                    : Image.asset(
                        imageSend,
                      ),
          ),
        ));
  }

  void _handleOpenGallery() async {
    final fileLen = Get.find<FileUploadCubit>().state.listFileUploading.length;
    if (fileLen == MAX_FILE_UPLOADING) {
      displayLimitationAlertDialog();
      return;
    }
    Get.find<GalleryCubit>().galleryInit();
    final bool isStatusGranted = await Utilities.checkCameraPermission();
    if (isStatusGranted) {
      Get.find<CameraCubit>().getCamera();
    } else {
      bool isRequestGranted = await Utilities.requestCameraPermission();
      if (isRequestGranted) {
        Get.find<CameraCubit>().getCamera();
      } else {
        Get.find<CameraCubit>().cameraFailed();
      }
    }

    Get.find<GalleryCubit>().getGalleryAssets();
    Get.find<FileTransitionCubit>().fileTransitionInit();

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(40),
          ),
        ),
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: GalleryView(),
          );
        });
  }

  void displayLimitationAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TwakeAlertDialog(
          header: Text(
            AppLocalizations.of(context)?.reachedLimitFileUploading ?? '',
            style: Theme.of(context).textTheme.headline4!.copyWith(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
            textAlign: TextAlign.center,
          ),
          body: Text(
            AppLocalizations.of(context)?.reachedLimitFileUploadingSub ?? '',
            style: Theme.of(context)
                .textTheme
                .headline6!
                .copyWith(fontSize: 14.0, color: const Color(0xff6d7885)),
            textAlign: TextAlign.center,
          ),
          okActionTitle: AppLocalizations.of(context)?.gotIt ?? '',
        );
      },
    );
  }
}
