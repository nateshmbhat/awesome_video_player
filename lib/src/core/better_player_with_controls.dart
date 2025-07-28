import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:awesome_video_player/awesome_video_player.dart';
import 'package:awesome_video_player/src/configuration/better_player_controller_event.dart';
import 'package:awesome_video_player/src/controls/better_player_cupertino_controls.dart';
import 'package:awesome_video_player/src/controls/better_player_material_controls.dart';
import 'package:awesome_video_player/src/core/better_player_utils.dart';
import 'package:awesome_video_player/src/subtitles/better_player_subtitles_drawer.dart';
import 'package:awesome_video_player/src/video_player/video_player.dart';
import 'package:flutter/material.dart';

class BetterPlayerWithControls extends StatefulWidget {
  final BetterPlayerController? controller;

  const BetterPlayerWithControls({Key? key, this.controller}) : super(key: key);

  @override
  _BetterPlayerWithControlsState createState() =>
      _BetterPlayerWithControlsState();
}

class _BetterPlayerWithControlsState extends State<BetterPlayerWithControls> {
  final StreamController<bool> playerVisibilityStreamController =
      StreamController();

  @override
  void initState() {
    playerVisibilityStreamController.add(true);
    super.initState();
  }

  @override
  void dispose() {
    playerVisibilityStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final betterPlayerController = BetterPlayerController.of(context);

    double? aspectRatio;
    if (betterPlayerController.isFullScreen) {
      if (betterPlayerController.betterPlayerConfiguration
              .autoDetectFullscreenDeviceOrientation ||
          betterPlayerController
              .betterPlayerConfiguration.autoDetectFullscreenAspectRatio) {
        aspectRatio =
            betterPlayerController.videoPlayerController?.value.aspectRatio ??
                1.0;
      } else {
        aspectRatio = betterPlayerController
                .betterPlayerConfiguration.fullScreenAspectRatio ??
            BetterPlayerUtils.calculateAspectRatio(context);
      }
    } else {
      aspectRatio = betterPlayerController.getAspectRatio();
    }

    aspectRatio ??= 16 / 9;
    final innerContainer = Container(
      width: double.infinity,
      color: betterPlayerController
          .betterPlayerConfiguration.controlsConfiguration.backgroundColor,
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: _InternalPlayerWithControlsWidget(
          playerVisibilityStream: playerVisibilityStreamController.stream,
          onControlsVisibilityChanged: onControlsVisibilityChanged,
        ),
      ),
    );

    if (betterPlayerController.betterPlayerConfiguration.expandToFill) {
      return Center(child: innerContainer);
    } else {
      return innerContainer;
    }
  }

  void onControlsVisibilityChanged(bool state) {
    playerVisibilityStreamController.add(state);
  }
}

///Widget used to set the proper box fit of the video. Default fit is 'fill'.
class _BetterPlayerVideoFitWidget extends StatefulWidget {
  const _BetterPlayerVideoFitWidget(
    this.betterPlayerController,
    this.boxFit, {
    Key? key,
  }) : super(key: key);

  final BetterPlayerController betterPlayerController;
  final BoxFit boxFit;

  @override
  _BetterPlayerVideoFitWidgetState createState() =>
      _BetterPlayerVideoFitWidgetState();
}

class _BetterPlayerVideoFitWidgetState
    extends State<_BetterPlayerVideoFitWidget> {
  VideoPlayerController? get controller =>
      widget.betterPlayerController.videoPlayerController;

  bool _initialized = false;

  VoidCallback? _initializedListener;

  bool _started = false;

  StreamSubscription? _controllerEventSubscription;

  @override
  void initState() {
    super.initState();
    if (!widget.betterPlayerController.betterPlayerConfiguration
        .showPlaceholderUntilPlay) {
      _started = true;
    } else {
      _started = widget.betterPlayerController.hasCurrentDataSourceStarted;
    }

    _initialize();
  }

  @override
  void didUpdateWidget(_BetterPlayerVideoFitWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betterPlayerController.videoPlayerController != controller) {
      if (_initializedListener != null) {
        oldWidget.betterPlayerController.videoPlayerController!
            .removeListener(_initializedListener!);
      }
      _initialized = false;
      _initialize();
    }
  }

  void _initialize() {
    if (controller?.value.initialized == false) {
      _initializedListener = () {
        if (!mounted) {
          return;
        }

        if (_initialized != controller!.value.initialized) {
          _initialized = controller!.value.initialized;
          setState(() {});
        }
      };
      controller!.addListener(_initializedListener!);
    } else {
      _initialized = true;
    }

    _controllerEventSubscription =
        widget.betterPlayerController.controllerEventStream.listen((event) {
      if (event == BetterPlayerControllerEvent.play) {
        if (!_started) {
          setState(() {
            _started =
                widget.betterPlayerController.hasCurrentDataSourceStarted;
          });
        }
      }
      if (event == BetterPlayerControllerEvent.setupDataSource) {
        setState(() {
          _started = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _started) {
      return Center(
        child: ClipRect(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: FittedBox(
              fit: widget.boxFit,
              child: SizedBox(
                width: controller!.value.size?.width ?? 0,
                height: controller!.value.size?.height ?? 0,
                child: VideoPlayer(controller),
              ),
            ),
          ),
        ),
      );
    } else {
      return const SizedBox();
    }
  }

  @override
  void dispose() {
    if (_initializedListener != null) {
      widget.betterPlayerController.videoPlayerController!
          .removeListener(_initializedListener!);
    }
    _controllerEventSubscription?.cancel();
    super.dispose();
  }
}

class _InternalPlayerWithControlsWidget extends StatelessWidget {
  final Stream<bool> playerVisibilityStream;
  final Function(bool) onControlsVisibilityChanged;

  const _InternalPlayerWithControlsWidget({
    required this.playerVisibilityStream,
    required this.onControlsVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final betterPlayerController = BetterPlayerController.of(context);
    final subtitlesConfiguration =
        betterPlayerController.betterPlayerConfiguration.subtitlesConfiguration;
    final controlsConfiguration =
        betterPlayerController.betterPlayerControlsConfiguration;
    final configuration = betterPlayerController.betterPlayerConfiguration;
    var rotation = configuration.rotation;

    if (!(rotation <= 360 && rotation % 90 == 0)) {
      BetterPlayerUtils.log("Invalid rotation provided. Using rotation = 0");
      rotation = 0;
    }
    if (betterPlayerController.betterPlayerDataSource == null) {
      return const SizedBox.shrink();
    }

    final placeholderOnTop =
        betterPlayerController.betterPlayerConfiguration.placeholderOnTop;
    // ignore: avoid_unnecessary_containers
    return Container(
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          if (placeholderOnTop) const _PlaceholderWidget(),
          Transform.rotate(
            angle: rotation * pi / 180,
            child: _BetterPlayerVideoFitWidget(
              betterPlayerController,
              betterPlayerController.getFit(),
            ),
          ),
          betterPlayerController.betterPlayerConfiguration.overlay ??
              const SizedBox.shrink(),
          if (subtitlesConfiguration.enabled)
            BetterPlayerSubtitlesDrawer(
              betterPlayerController: betterPlayerController,
              betterPlayerSubtitlesConfiguration: subtitlesConfiguration,
              subtitles: betterPlayerController.subtitlesLines,
              playerVisibilityStream: playerVisibilityStream,
            ),
          if (!placeholderOnTop) const _PlaceholderWidget(),
          _ControlsWidget(
            controlsConfiguration: controlsConfiguration,
            betterPlayerController: betterPlayerController,
            onControlsVisibilityChanged: onControlsVisibilityChanged,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderWidget extends StatelessWidget {
  const _PlaceholderWidget();

  @override
  Widget build(BuildContext context) {
    final betterPlayerController = BetterPlayerController.of(context);
    return betterPlayerController.betterPlayerDataSource!.placeholder ??
        betterPlayerController.betterPlayerConfiguration.placeholder ??
        Container();
  }
}

class _ControlsWidget extends StatelessWidget {
  final BetterPlayerControlsConfiguration controlsConfiguration;
  final BetterPlayerController betterPlayerController;
  final Function(bool) onControlsVisibilityChanged;

  const _ControlsWidget({
    required this.controlsConfiguration,
    required this.betterPlayerController,
    required this.onControlsVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (controlsConfiguration.showControls) {
      BetterPlayerTheme? playerTheme = controlsConfiguration.playerTheme;
      if (playerTheme == null) {
        if (Platform.isAndroid) {
          playerTheme = BetterPlayerTheme.material;
        } else {
          playerTheme = BetterPlayerTheme.cupertino;
        }
      }

      if (controlsConfiguration.customControlsBuilder != null &&
          playerTheme == BetterPlayerTheme.custom) {
        return controlsConfiguration.customControlsBuilder!(
            betterPlayerController, onControlsVisibilityChanged);
      } else if (playerTheme == BetterPlayerTheme.material) {
        return BetterPlayerMaterialControls(
          onControlsVisibilityChanged: onControlsVisibilityChanged,
          controlsConfiguration: controlsConfiguration,
        );
      } else if (playerTheme == BetterPlayerTheme.cupertino) {
        return BetterPlayerCupertinoControls(
          onControlsVisibilityChanged: onControlsVisibilityChanged,
          controlsConfiguration: controlsConfiguration,
        );
      }
    }

    return const SizedBox();
  }
}
