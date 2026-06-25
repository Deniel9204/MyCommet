import 'package:commet/client/attachment.dart';
import 'package:commet/utils/mime.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiamat/tiamat.dart';

class AttachmentIcon extends StatefulWidget {
  const AttachmentIcon(this.attachment, {super.key, this.removeAttachment});
  final PendingFileAttachment attachment;
  final Function()? removeAttachment;

  @override
  State<AttachmentIcon> createState() => _AttachmentIconState();
}

class _AttachmentIconState extends State<AttachmentIcon> {
  ImageProvider? image;

  @override
  void initState() {
    if (Mime.imageTypes.contains(widget.attachment.mimeType) &&
        widget.attachment.data != null) {
      image = Image.memory(widget.attachment.data!).image;
    }

    if (widget.attachment.thumbnailFile != null) {
      image = Image.memory(widget.attachment.thumbnailFile!).image;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ImageButton(
          size: 20,
          image: image,
          icon: Mime.toIcon(widget.attachment.mimeType),
          onTap: widget.removeAttachment,
          iconSize: 20,
        ),
        // Visible "remove" affordance. The whole tile already removes on tap,
        // so this is an ignore-pointer badge that just makes that discoverable.
        if (widget.removeAttachment != null)
          const Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(1),
                  child: Icon(Icons.close, size: 13, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
