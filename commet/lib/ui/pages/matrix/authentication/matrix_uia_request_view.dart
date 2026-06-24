import 'package:commet/utils/common_strings.dart';
import 'package:commet/utils/uia_stage.dart';
import 'package:flutter/widgets.dart';
// have to do it this way to avoid some widgetbook codegen issue
// ignore: implementation_imports
import 'package:matrix/src/utils/uia_request.dart';
import 'package:tiamat/tiamat.dart';
import 'package:tiamat/tiamat.dart' as tiamat;
import 'package:flutter/material.dart' as material;

class MatrixUIARequestView extends StatefulWidget {
  const MatrixUIARequestView(
    this.state, {
    this.stage = UiaStageKind.password,
    this.onSubmitAuthentication,
    this.onOpenSso,
    this.onCompleteSso,
    this.onCancel,
    super.key,
    this.onFail,
    this.onSuccess,
  });
  final UiaRequestState state;
  final UiaStageKind stage;
  final Function(String password)? onSubmitAuthentication;
  final Function()? onOpenSso;
  final Function()? onCompleteSso;
  final Function()? onCancel;
  final Function()? onSuccess;
  final Function()? onFail;

  @override
  State<MatrixUIARequestView> createState() => _MatrixUIARequestViewState();
}

class _MatrixUIARequestViewState extends State<MatrixUIARequestView> {
  TextEditingController passwordFieldController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      height: 200,
      child: buildView(),
    );
  }

  Widget buildView() {
    switch (widget.state) {
      case UiaRequestState.done:
        return done(context);
      case UiaRequestState.fail:
        return fail(context);
      case UiaRequestState.loading:
        return loading();
      case UiaRequestState.waitForUser:
        return waitForUser();
    }
  }

  Widget waitForUser() {
    switch (widget.stage) {
      case UiaStageKind.password:
        return userPasswordInput();
      case UiaStageKind.sso:
        return ssoInput();
      case UiaStageKind.dummy:
        // The controller completes the dummy stage automatically.
        return loading();
      case UiaStageKind.unsupported:
        return unsupported();
    }
  }

  Widget userPasswordInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextInput(
          placeholder: "Account Password",
          obscureText: true,
          controller: passwordFieldController,
        ),
        Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                  width: 100,
                  height: 40,
                  child: Button(
                    text: CommonStrings.promptSubmit,
                    onTap: () => widget.onSubmitAuthentication
                        ?.call(passwordFieldController.text),
                  )),
            ))
      ],
    );
  }

  Widget ssoInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text(
              "Authenticate with your single sign-on provider, then continue."),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 40,
                child: Button(
                  text: "Open sign-on",
                  onTap: () => widget.onOpenSso?.call(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                height: 40,
                child: Button(
                  text: CommonStrings.promptContinue,
                  onTap: () => widget.onCompleteSso?.call(),
                ),
              ),
            ),
          ],
        ),
        cancelButton(),
      ],
    );
  }

  Widget unsupported() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: tiamat.Text(
              "This account requires an authentication method that isn't supported in the app yet."),
        ),
        cancelButton(),
      ],
    );
  }

  Widget cancelButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40,
        width: 120,
        child: tiamat.Button.danger(
          text: CommonStrings.promptCancel,
          onTap: () => widget.onCancel?.call(),
        ),
      ),
    );
  }

  Widget loading() {
    return const Center(
      child: material.CircularProgressIndicator(),
    );
  }

  Widget done(BuildContext context) {
    Navigator.pop(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                material.Icons.verified_user_rounded,
                color: material.Colors.green.shade400,
                size: 40,
              ),
            ),
            const tiamat.Text.largeTitle("Success!")
          ],
        ),
        SizedBox(
          height: 40,
          width: 200,
          child: tiamat.Button.success(
            text: CommonStrings.promptContinue,
            onTap: () => widget.onSuccess?.call(),
          ),
        )
      ],
    );
  }

  Widget fail(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                material.Icons.error_outline,
                color: material.Theme.of(context).colorScheme.error,
                size: 40,
              ),
            ),
            const tiamat.Text.largeTitle("Login failed...")
          ],
        ),
        SizedBox(
          height: 40,
          width: 200,
          child: tiamat.Button.danger(
            text: CommonStrings.promptContinue,
            onTap: () => widget.onFail?.call(),
          ),
        )
      ],
    );
  }
}
