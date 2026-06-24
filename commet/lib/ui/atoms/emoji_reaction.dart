import 'package:commet/client/components/emoticon/emoticon.dart';
import 'package:commet/utils/reaction_semantic_label.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

import 'emoji_widget.dart';

class EmojiReaction extends StatelessWidget {
  const EmojiReaction(
      {required this.emoji,
      required this.numReactions,
      this.highlighted = false,
      this.onTapped,
      this.onLongPressed,
      super.key});

  final Function(Emoticon emote)? onTapped;
  final Function(Emoticon emote)? onLongPressed;
  final Emoticon emoji;
  final int numReactions;
  final bool highlighted;

  BorderRadius get borderRadius => BorderRadius.circular(8);

  String get _reactionSingular => Intl.message("reaction",
      name: "reactionSemanticSingular",
      desc: "Screen-reader noun for a single message reaction");

  String get _reactionPlural => Intl.message("reactions",
      name: "reactionSemanticPlural",
      desc: "Screen-reader noun for multiple message reactions");

  @override
  Widget build(BuildContext context) {
    var bgColor = material.Theme.of(context).colorScheme.primary;

    if (!highlighted) {
      bgColor = material.Theme.of(context).colorScheme.surfaceContainerLow;
    }

    return Semantics(
        button: true,
        toggled: highlighted,
        label: buildReactionSemanticLabel(
          emojiName: emoji.shortcode ?? emoji.slug,
          count: numReactions,
          reactionSingular: _reactionSingular,
          reactionPlural: _reactionPlural,
        ),
        child: material.InkWell(
          onTap: () => onTapped?.call(emoji),
          onLongPress: () => onLongPressed?.call(emoji),
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
                color: bgColor.withAlpha(70),
                border: Border.all(color: bgColor, width: 1),
                borderRadius: borderRadius),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 3, 5, 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EmojiWidget(
                    emoji,
                    height: 17,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  tiamat.Text.label(numReactions.toString()),
                  const SizedBox(
                    width: 3,
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
