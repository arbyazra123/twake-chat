import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:twake/blocs/message_animation_cubit/message_animation_cubit.dart';

class EmojiBoard extends StatelessWidget {
  final void Function(String) onEmojiSelected;

  EmojiBoard({required this.onEmojiSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (cat, emoji) {
          onEmojiSelected(emoji.emoji);
          Get.find<MessageAnimationCubit>().endAnimation();
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
    );
  }
}
