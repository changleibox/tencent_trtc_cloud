import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'trtc_cloud_def.dart';

/// @nodoc
/// channel标识符
String channelType = TRTCCloudDef.TRTC_VideoView_SurfaceView;

/// @nodoc
/// Flutter 支持两种集成模式：虚拟显示模式 (Virtual displays) 和混合集成模式 (Hybrid composition) 。
String viewMode = TRTCCloudDef.TRTC_VideoView_Model_Virtual;

/// 视频view窗口,显示本地视频、远端视频或辅流
///
/// 注意：TRTCCloudVideoView仅支持安卓和IOS
///
/// 参数：
///
/// onViewCreated: view创建后的回调，生成的当前viewId
///
/// key: Widget key，可以不传
///
/// viewType: 该参数仅对安卓有效，可以不传
///
/// 安卓视频渲染所用的view组件类型，有两个组件可以选择SurfaceView和TextureView。默认为SurfaceView
///
/// 如果想用TextureView进行渲染，则viewType传TRTCCloudDef.TRTC_VideoView_TextureView
///
/// 如果想用SurfaceView进行渲染，则viewType传TRTCCloudDef.TRTC_VideoView_SurfaceView
class TRTCCloudVideoView extends StatefulWidget {
  final ValueChanged<int>? onViewCreated;
  final String? viewType;
  final String? viewMode;
  final CustomRender? textureParam;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  const TRTCCloudVideoView(
      {Key? key,
      this.viewType,
      this.viewMode,
      this.textureParam,
      this.onViewCreated,
      this.gestureRecognizers})
      : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      TRTCCloudVideoViewState(this.viewType, this.viewMode, this.textureParam);
}

//// @nodoc
class TRTCCloudVideoViewState extends State<TRTCCloudVideoView> {
  int? _textureId;
  CustomRender? _textureParam;
  TRTCCloudVideoViewState(
      String? viewType, String? mode, CustomRender? textureParam) {
    _textureParam = textureParam;
    if (viewType != null) {
      channelType = viewType;
    }
    if (mode != null) {
      viewMode = mode;
    }
    if (Platform.isAndroid && viewType != null) {
      channelType = viewType;
    } else if (Platform.isIOS || kIsWeb) {
      channelType = TRTCCloudDef.TRTC_VideoView_TextureView;
    } else {
      // Mac/Windows只支持纹理渲染
      channelType = TRTCCloudDef.TRTC_VideoView_Texture;
    }
  }

  @override
  void didUpdateWidget(TRTCCloudVideoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textureParam != null && Platform.isAndroid) {
      if (widget.textureParam!.width != oldWidget.textureParam!.width ||
          widget.textureParam!.height != oldWidget.textureParam!.height) {
        if (widget.textureParam!.isLocal) {
          //宽高变化时更新宽高，为了保证不变形可能会有黑边，如果不想要黑边可以调用setVideoEncoderParam设置接近宽高的分辨率
          MethodChannel('trtcCloudChannel').invokeMethod(
              'updateLocalVideoRender', {
            "width": widget.textureParam!.width,
            "height": widget.textureParam!.height
          });
        } else {
          MethodChannel('trtcCloudChannel')
              .invokeMethod('updateRemoteVideoRender', {
            "textureID": _textureId,
            "width": widget.textureParam!.width,
            "height": widget.textureParam!.height
          });
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (channelType == TRTCCloudDef.TRTC_VideoView_Texture &&
        _textureParam != null) {
      if (_textureParam!.isLocal) {
        MethodChannel('trtcCloudChannel')
            .invokeMethod('setLocalVideoRenderListener', {
          "userId": _textureParam!.userId,
          "isFront":
              _textureParam!.isFront == null ? true : _textureParam!.isFront,
          "streamType": _textureParam!.streamType,
          "width": _textureParam!.width,
          "height": _textureParam!.height
        }).then((value) => {
                  setState(() {
                    _textureId = value;
                  })
                });
      } else {
        MethodChannel('trtcCloudChannel')
            .invokeMethod('setRemoteVideoRenderListener', {
          "userId": _textureParam!.userId,
          "streamType": _textureParam!.streamType,
          "width": _textureParam!.width,
          "height": _textureParam!.height
        }).then((value) => {
                  setState(() {
                    _textureId = value;
                  })
                });
      }
      return;
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (channelType == TRTCCloudDef.TRTC_VideoView_Texture &&
        _textureId != null) {
      MethodChannel('trtcCloudChannel')
          .invokeMethod('unregisterTexture', {"textureID": _textureId});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (channelType == TRTCCloudDef.TRTC_VideoView_Texture) {
      if (_textureId != null) {
        return Texture(textureId: _textureId!);
      }
      return Container();
    }
    if (kIsWeb) {
      return PlatformViewLink(
        viewType: channelType,
        surfaceFactory:
            (BuildContext context, PlatformViewController controller) {
          return PlatformViewSurface(
            controller: controller,
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            gestureRecognizers: widget.gestureRecognizers != null
                ? widget.gestureRecognizers!
                : const <Factory<OneSequenceGestureRecognizer>>{},
          );
        },
        onCreatePlatformView: (PlatformViewCreationParams params) {
          final controller =
              _HtmlElementViewController(params.id, params.viewType);
          controller._initialize().then((_) {
            params.onPlatformViewCreated(params.id);
            _onPlatformViewCreated(params.id);
          });
          return controller;
        },
      );
    } else if (Platform.isAndroid) {
      if (viewMode == TRTCCloudDef.TRTC_VideoView_Model_Virtual) {
        //虚拟现实模式
        return AndroidView(
          viewType: channelType,
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: widget.gestureRecognizers,
        );
      } else {
        //混合集成模式
        return PlatformViewLink(
          viewType: channelType,
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) {
            return PlatformViewSurface(
              controller: controller as AndroidViewController,
              hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              gestureRecognizers: widget.gestureRecognizers != null
                  ? widget.gestureRecognizers!
                  : const <Factory<OneSequenceGestureRecognizer>>{},
            );
          },
          onCreatePlatformView: (PlatformViewCreationParams params) {
            return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: channelType,
              layoutDirection: TextDirection.ltr,
              creationParamsCodec: StandardMessageCodec(),
            )
              ..addOnPlatformViewCreatedListener((id) {
                params.onPlatformViewCreated(id);
                _onPlatformViewCreated(id);
              })
              ..create();
          },
        );
      }
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: channelType,
        onPlatformViewCreated: _onPlatformViewCreated,
        gestureRecognizers: widget.gestureRecognizers,
      );
    } else {
      return Center(
        child: Text(
          "该平台不支持Platform View",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
      );
    }
  }

  void _onPlatformViewCreated(int id) {
    widget.onViewCreated!(id);
  }
}

class _HtmlElementViewController extends PlatformViewController
    with WidgetsBindingObserver {
  _HtmlElementViewController(
    this.viewId,
    this.viewType,
  );

  @override
  final int viewId;

  /// The unique identifier for the HTML view type to be embedded by this widget.
  ///
  /// A PlatformViewFactory for this type must have been registered.
  final String viewType;

  bool _initialized = false;

  Future<void> _initialize() async {
    final args = <String, dynamic>{
      'id': viewId,
      'viewType': viewType,
    };
    await SystemChannels.platform_views.invokeMethod<void>('create', args);
    _initialized = true;
  }

  @override
  Future<void> clearFocus() async {
    // Currently this does nothing on Flutter Web.
    // TODO(het): Implement this. See https://github.com/flutter/flutter/issues/39496
  }

  @override
  Future<void> dispatchPointerEvent(PointerEvent event) async {
    // We do not dispatch pointer events to HTML views because they may contain
    // cross-origin iframes, which only accept user-generated events.
  }

  @override
  Future<void> dispose() async {
    if (_initialized) {
      await SystemChannels.platform_views.invokeMethod<void>('dispose', viewId);
    }
  }
}

/// @nodoc
/// 视频控制器方法
class TRTCCloudVideoViewController {
  TRTCCloudVideoViewController(int id)
      : _channel = new MethodChannel(channelType + '_$id');

  final MethodChannel _channel;

  /// 开启本地视频的预览画面
  ///
  /// 当开始渲染首帧摄像头画面时，您会收到 TRTCCloudListener 中的 onFirstVideoFrame(null) 回调。
  ///
  /// 参数：
  ///
  /// frontCamera	true：前置摄像头；false：后置摄像头
  Future<void> startLocalPreview(
    bool frontCamera, // true：前置摄像头；false：后置摄像头。
  ) {
    return _channel.invokeMethod('startLocalPreview', {
      "frontCamera": frontCamera,
    });
  }

  /// 更新本地视频预览画面的窗口,仅仅ios有效
  ///
  /// 参数：
  ///
  /// viewId	承载视频画面的控件
  Future<void> updateLocalView(viewId) {
    return _channel.invokeMethod('updateLocalView', {
      "viewId": viewId,
    });
  }

  /// 更新远端视频画面的窗口,仅仅ios有效
  ///
  /// 参数：
  ///
  /// viewId	承载视频画面的控件
  ///
  /// userId 指定远端用户的 userId
  ///
  /// streamType 指定要观看 userId 的视频流类型：
  Future<void> updateRemoteView(viewId, streamType, userId) {
    return _channel.invokeMethod(
      'updateRemoteView',
      {"viewId": viewId, "streamType": streamType, "userId": userId},
    );
  }

  /// 显示远端视频或辅流
  ///
  /// 参数：
  ///
  /// userId 指定远端用户的 userId
  ///
  /// streamType 指定要观看 userId 的视频流类型：
  ///
  ///* 高清大画面：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG
  ///
  ///* 低清大画面：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SMALL
  ///
  ///* 辅流（屏幕分享）：TRTCCloudDe.TRTC_VIDEO_STREAM_TYPE_SUB
  Future<void> startRemoteView(
      String userId, // 用户ID
      int streamType) {
    return _channel.invokeMethod(
        'startRemoteView', {"userId": userId, "streamType": streamType});
  }
}
