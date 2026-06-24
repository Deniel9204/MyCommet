import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request_view.dart';
import 'package:commet/utils/uia_stage.dart';
import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../client/matrix/matrix_client.dart';

class MatrixUIARequest extends StatefulWidget {
  const MatrixUIARequest(this.request, this.client, {super.key});
  final UiaRequest request;
  final MatrixClient client;
  @override
  State<MatrixUIARequest> createState() => _MatrixUIARequestState();
}

class _MatrixUIARequestState extends State<MatrixUIARequest> {
  void Function(UiaRequestState)? originalOnUpdate;
  late UiaRequestState state;

  /// Guards against re-submitting the dummy stage while it is in flight.
  bool _completingDummy = false;

  @override
  void initState() {
    state = widget.request.state;

    originalOnUpdate = widget.request.onUpdate;
    widget.request.onUpdate = onUpdate;

    super.initState();

    _maybeAutoCompleteDummy();
  }

  void onUpdate(UiaRequestState state) {
    setState(() {
      this.state = state;
    });

    originalOnUpdate?.call(state);

    _maybeAutoCompleteDummy();
  }

  UiaStageKind get stage => resolveUiaStage(widget.request.nextStages);

  /// A dummy stage needs no input, so complete it automatically rather than
  /// showing the user a pointless prompt.
  void _maybeAutoCompleteDummy() {
    if (state == UiaRequestState.waitForUser &&
        stage == UiaStageKind.dummy &&
        !_completingDummy) {
      _completingDummy = true;
      widget.request.completeStage(
        AuthenticationData(
          type: UiaStageTypes.dummy,
          session: widget.request.session,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MatrixUIARequestView(
      state,
      stage: stage,
      onSubmitAuthentication: submitAuthentication,
      onOpenSso: openSso,
      onCompleteSso: completeSso,
      onCancel: cancel,
      onSuccess: () => Navigator.of(context).pop(),
      onFail: () => Navigator.of(context).pop(),
    );
  }

  void submitAuthentication(String password) {
    // Authenticate as the actual logged-in user (previously hardcoded to
    // "alice", which made the request fail and loop forever), and carry the
    // UIA session so the homeserver ties this to the right flow.
    final userId = widget.client.getMatrixClient().userID;
    widget.request.completeStage(AuthenticationPassword(
      password: password,
      identifier: AuthenticationUserIdentifier(user: userId ?? ""),
      session: widget.request.session,
    ));
  }

  Future<void> openSso() async {
    final mxClient = widget.client.getMatrixClient();
    final session = widget.request.session;

    // Send the user through the homeserver's SSO fallback page; on return they
    // confirm and we complete the stage.
    final url = Uri.parse(
        "${mxClient.homeserver}/_matrix/client/v3/auth/${UiaStageTypes.sso}/fallback/web?session=$session");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void completeSso() {
    widget.request.completeStage(AuthenticationData(
      type: UiaStageTypes.sso,
      session: widget.request.session,
    ));
  }

  void cancel() {
    widget.request.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
