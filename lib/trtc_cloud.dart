import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'trtc_cloud_def.dart';
import 'trtc_cloud_listener.dart';
import 'trtc_cloud_video_view.dart';
import 'tx_audio_effect_manager.dart';
import 'tx_beauty_manager.dart';
import 'tx_device_manager.dart';

/// 腾讯云视频通话功能的主要接口类
class TRTCCloud {
  static TRTCCloud? _trtcCloud;

  static const MethodChannel _channel = const MethodChannel('trtcCloudChannel');

  static TRTCCloudListenerObj? listener;

  static Future<String?> getPlatformVersion() async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  /// 创建 TRTCCloud 单例。
  static Future<TRTCCloud?> sharedInstance() async {
    if (_trtcCloud == null) {
      _trtcCloud = new TRTCCloud();
      await _channel.invokeMethod('sharedInstance');
    }
    return _trtcCloud;
  }

  /// 销毁 TRTCCloud 单例。
  static Future<void> destroySharedInstance() async {
    await _channel.invokeMethod('destroySharedInstance');
    _trtcCloud = null;
  }

  /// 设置事件监听，用户获得来自 TRTCCloud 的各种状态通知
  ///
  /// 详见 trtc_cloud_listener文件中TRTCCloudListenerEnum中的定义
  void registerListener(ListenerValue func) {
    if (listener == null) {
      listener = TRTCCloudListenerObj(_channel);
    }
    listener!.addListener(func);
  }

  /// 移除消息监听。
  void unRegisterListener(ListenerValue func) {
    if (listener == null) {
      listener = TRTCCloudListenerObj(_channel);
    }
    listener!.removeListener(func);
  }

  /// 进入房间
  ///
  /// 调用接口后，您会收到来自 TRTCCloudListener 中的 onEnterRoom(result) 回调：
  ///
  /// 如果加入成功，result 会是一个正数（result > 0），表示加入房间所消耗的时间，单位是毫秒（ms）。
  ///
  /// 如果加入失败，result 会是一个负数（result < 0），表示进房失败的错误码。
  ///
  /// 参数：
  ///
  /// param	进房参数，请参考 trtc_cloud_def.dart文件中的TRTCParams参数定义
  ///
  /// scene	应用场景，目前支持视频通话（VideoCall）、在线直播（Live）、语音通话（AudioCall）、语音聊天室（VoiceChatRoom）四种场景。
  ///
  /// 注意：
  ///
  /// 1.当 scene 选择为 TRTC_APP_SCENE_LIVE 或 TRTC_APP_SCENE_VOICE_CHATROOM 时，您必须通过 TRTCParams 中的 role 字段指定当前用户的角色。
  ///
  /// 2.不管进房是否成功，enterRoom 都必须与 exitRoom 配对使用，在调用 exitRoom 前再次调用 enterRoom 函数会导致不可预期的错误问题。
  Future<void> enterRoom(TRTCParams param, int scene) {
    if (kIsWeb || Platform.isAndroid || Platform.isWindows) {
      return _channel.invokeMethod('enterRoom', {
        "sdkAppId": param.sdkAppId,
        "userId": param.userId,
        "userSig": param.userSig,
        "roomId": param.roomId.toString(),
        "strRoomId": param.strRoomId,
        "role": param.role,
        "streamId": param.streamId,
        "userDefineRecordId": param.userDefineRecordId,
        "privateMapKey": param.privateMapKey,
        "businessInfo": param.businessInfo,
        "scene": scene,
      });
    } else {
      return _channel.invokeMethod('enterRoom', {
        "param": jsonEncode(param),
        "scene": scene,
      });
    }
  }

  /// 开始本地视频自定义视频渲染，利用外接纹理的方式进视频渲染。
  ///
  /// 设置此方法后，SDK 内部会跳过自己原来的渲染流程，并把采集到的数据回调出来，您需要自己完成画面的渲染。
  ///
  /// 参数 见CustomRender定义
  ///
  /// 返回 textureId 纹理id
  ///
  /// 参考文档：[自定义采集和渲染](https://cloud.tencent.com/document/product/647/34066)
  ///
  /// 调用示例
  ///
  /// var textureId = await trtcCloud.setLocalVideoRenderListener(
  ///            CustomLocalRender(
  ///               userId: userInfo['userId'],
  ///                isFront: true,
  ///                streamType: TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG,
  ///                width: 360,
  ///                height: 738));
  ///
  /// Texture(key: valueKey, textureId: textureId)
  ///
  /// 调用时机：在进房成功的时候调用
  Future<int?> setLocalVideoRenderListener(CustomLocalRender param) {
    return _channel.invokeMethod('setLocalVideoRenderListener', {
      "userId": param.userId,
      "isFront": param.isFront,
      "streamType": param.streamType,
      "width": param.width,
      "height": param.height,
    });
  }

  /// @nodoc
  ///
  /// 更新本地视频的宽度和高度
  Future<void> updateLocalVideoRender(int width, int height) {
    return _channel.invokeMethod('updateLocalVideoRender', {
      "width": width,
      "height": height,
    });
  }

  /// @nodoc
  ///
  /// 更新远端视频的宽度和高度
  Future<void> updateRemoteVideoRender(int textureID, int width, int height) {
    return _channel.invokeMethod('updateRemoteVideoRender', {
      "textureID": textureID,
      "width": width,
      "height": height,
    });
  }

  /// 开始自定义视频渲染，利用外接纹理的方式进视频渲染。
  ///
  /// 参数 见CustomRender定义
  ///
  /// 返回 textureId 纹理id
  ///
  /// 参考文档：[自定义采集和渲染](https://cloud.tencent.com/document/product/647/34066)
  ///
  /// 调用示例
  ///
  /// var textureId = await trtcCloud.setRemoteVideoRenderListener(
  ///        CustomRemoteRender(
  ///            userId: userId,
  ///            streamType: TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG,
  ///            width: 360,
  ///            height: 369));
  ///
  /// Texture(key: valueKey, textureId: textureId)
  ///
  /// 调用时机：在onUserVideoAvailable为true的时候调用
  Future<int?> setRemoteVideoRenderListener(CustomRemoteRender param) {
    return _channel.invokeMethod('setRemoteVideoRenderListener', {
      "userId": param.userId,
      "streamType": param.streamType,
      "width": param.width,
      "height": param.height,
    });
  }

  /// 注销纹理
  ///
  /// 调用 setLocalVideoRenderListener 或者 setRemoteVideoRenderListener 的时候生成的 textureID 。该纹理不需要的时候需要调用该接口注销
  ///
  /// 调用时机：在 onUserVideoAvailable 为false 的时候调用或者是页面 dispose 的时候
  Future<void> unregisterTexture(int textureID) {
    return _channel.invokeMethod('unregisterTexture', {
      "textureID": textureID,
    });
  }

  /// 离开房间。
  ///
  /// 调用 exitRoom() 接口会执行退出房间的相关逻辑，例如释放音视频设备资源和编解码器资源等。 待资源释放完毕，SDK 会通过 onExitRoom() 回调通知到您。
  ///
  /// 如果您要再次调用 enterRoom() 或者切换到其他的音视频 SDK，请等待 onExitRoom() 回调到来之后再执行相关操作。 否则可能会遇到摄像头或麦克风被占用等各种异常问题，例如常见的 Android 媒体音量和通话音量切换问题等等。
  Future<void> exitRoom() {
    return _channel.invokeMethod('exitRoom');
  }

  /// 请求跨房通话（主播 PK）
  ///
  /// TRTC 中两个不同音视频房间中的主播，可以通过“跨房通话”功能拉通连麦通话功能。使用此功能时， 两个主播无需退出各自原来的直播间即可进行“连麦 PK”。
  ///
  /// 例如：当房间“001”中的主播 A 通过 connectOtherRoom() 跟房间“002”中的主播 B 拉通跨房通话后， 房间“001”中的用户都会收到主播 B 的 onRemoteUserEnterRoom(B) 回调和 onUserVideoAvailable(B,true) 回调。 房间“002”中的用户都会收到主播 A 的 onRemoteUserEnterRoom(A) 回调和 onUserVideoAvailable(A,true) 回调。
  ///
  /// 简言之，跨房通话的本质，就是把两个不同房间中的主播相互分享，让每个房间里的观众都能看到两个主播。
  ///
  /// 跨房通话的参数考虑到后续扩展字段的兼容性问题，暂时采用了 JSON 格式的参数，要求至少包含两个字段：
  ///
  /// * roomId：房间“001”中的主播 A 要跟房间“002”中的主播 B 连麦，主播 A 调用 ConnectOtherRoom() 时 roomId 应指定为“002”。
  ///
  /// * userId：房间“001”中的主播 A 要跟房间“002”中的主播 B 连麦，主播 A 调用 ConnectOtherRoom() 时 userId 应指定为 B 的 userId。
  ///
  /// 跨房通话的请求结果会通过 onConnectOtherRoom() 回调通知给您。
  ///
  /// 调用示例：
  ///
  /// var object = new Map();
  ///
  /// object['roomId'] = 155;
  ///
  /// object['userId'] = '57890';
  ///
  /// trtcCloud.connectOtherRoom(jsonEncode(object));
  ///
  /// 参数：
  ///
  /// param	JSON 字符串连麦参数，roomId 代表目标房间号，userId 代表目标用户 ID。
  Future<void> connectOtherRoom(String param) {
    return _channel.invokeMethod('connectOtherRoom', {
      "param": param,
    });
  }

  /// 退出跨房通话
  ///
  /// 跨房通话的退出结果会通过onDisconnectOtherRoom 回调通知给您。
  Future<void> disconnectOtherRoom() {
    return _channel.invokeMethod('disconnectOtherRoom');
  }

  /// 切换角色，仅适用于直播场景（TRTC_APP_SCENE_LIVE 和 TRTC_APP_SCENE_VOICE_CHATROOM）。
  ///
  /// 在直播场景下，一个用户可能需要在“观众”和“主播”之间来回切换。 您可以在进房前通过 TRTCParams 中的 role 字段确定角色，也可以通过 switchRole 在进房后切换角色。
  ///
  /// 参数param：
  ///
  /// role	目标角色，默认为主播：
  ///
  /// TRTCCloudDef.TRTCRoleAnchor 主播，可以上行视频和音频，一个房间里最多支持50个主播同时上行音视频。
  ///
  /// TRTCCloudDef.TRTCRoleAudience 观众，只能观看，不能上行视频和音频，一个房间里的观众人数没有上限。

  Future<void> switchRole(int role) {
    return _channel.invokeMethod('switchRole', {
      "role": role,
    });
  }

  /// 设置音视频数据接收模式（需要在进房前设置才能生效）。
  ///
  /// 为实现进房秒开的绝佳体验，SDK 默认进房后自动接收音视频。即在您进房成功的同时，您将立刻收到远端所有用户的音视频数据。 若您没有调用 startRemoteView，视频数据将自动超时取消。 若您主要用于语音聊天等没有自动接收视频数据需求的场景，您可以根据实际需求选择接收模式。
  ///
  /// 参数：
  ///
  /// autoRecvAudio	true：自动接收音频数据；false：需要调用 muteRemoteAudio 进行请求或取消。默认值：true
  ///
  /// autoRecvVideo	true：自动接收视频数据；false：需要调用 startRemoteView/stopRemoteView 进行请求或取消。默认值：true
  ///
  /// 注意：需要在进房前设置才能生效。
  Future<void> setDefaultStreamRecvMode(bool autoRecvAudio, bool autoRecvVideo) {
    return _channel.invokeMethod('setDefaultStreamRecvMode', {
      "autoRecvAudio": autoRecvAudio,
      "autoRecvVideo": autoRecvVideo,
    });
  }

  /// 切换房间
  ///
  /// 调用接口后，会退出原来的房间，并且停止原来房间的音视频数据发送和所有远端用户的音视频播放，但不会停止本地视频的预览。 进入新房间成功后，会自动恢复原来的音视频数据发送状态。
  ///
  /// 接口调用结果会通过onSwitchRoom(errCode, errMsg) 回调。
  Future<void> switchRoom(TRTCSwitchRoomConfig config) {
    return _channel.invokeMethod('switchRoom', {
      "config": jsonEncode(config),
    });
  }

  /// 开始向腾讯云的直播 CDN 推流
  ///
  /// 该接口会指定当前用户的音视频流在腾讯云 CDN 所对应的 StreamId，进而可以指定当前用户的 CDN 播放地址。
  ///
  /// 例如：如果我们采用如下代码设置当前用户的主画面 StreamId 为 user_stream_001，那么该用户主画面对应的 CDN 播放地址为： “http://yourdomain/live/user_stream_001.flv”，其中 yourdomain 为您自己备案的播放域名， 您可以在[直播控制台](https://console.cloud.tencent.com/live) 配置您的播放域名，腾讯云不提供默认的播放域名。
  ///
  /// 您也可以在设置 enterRoom 的参数 TRTCParams 时指定 streamId, 而且我们更推荐您采用这种方案。
  ///
  /// 参数：
  ///
  /// streamId	自定义流 ID。
  ///
  /// streamType	仅支持 TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG 和 TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SUB。
  ///
  /// 注意：
  ///
  /// 您需要先在实时音视频 [控制台](https://console.cloud.tencent.com/trtc) 中的功能配置页开启“启用旁路推流”才能生效。
  ///
  /// *若您选择“指定流旁路”，则您可以通过该接口将对应音视频流推送到腾讯云 CDN 且指定为填写的流 ID。
  ///
  /// *若您选择“全局自动旁路”，则您可以通过该接口调整默认的流 ID。
  Future<void> startPublishing(String streamId, int streamType) {
    return _channel.invokeMethod('startPublishing', {
      "streamId": streamId,
      "streamType": streamType,
    });
  }

  /// 停止向腾讯云的直播 CDN 推流
  Future<void> stopPublishing() {
    return _channel.invokeMethod('stopPublishing');
  }

  /// 开始向友商云的直播 CDN 转推
  ///
  /// 该接口跟 startPublishing() 类似，但 startPublishCDNStream() 支持向非腾讯云的直播 CDN 转推。
  ///
  /// 参数
  ///
  /// param	CDN 转推参数，请参考 TRTCPublishCDNParam
  ///
  /// 注意：
  ///
  /// 使用 startPublishing() 绑定腾讯云直播 CDN 不收取额外的费用，但使用 startPublishCDNStream() 绑定非腾讯云直播 CDN 需要收取转推费用。
  Future<void> startPublishCDNStream(TRTCPublishCDNParam param) {
    return _channel.invokeMethod('startPublishCDNStream', {
      "param": jsonEncode(param),
    });
  }

  /// 停止向非腾讯云地址转推
  Future<void> stopPublishCDNStream() {
    return _channel.invokeMethod('stopPublishCDNStream');
  }

  /// 设置云端的混流转码参数。
  ///
  /// 如果您在实时音视频 控制台 中的功能配置页开启了“启用旁路推流”功能， 房间里的每一路画面都会有一个默认的直播 CDN 地址。
  ///
  /// 一个直播间中可能有不止一位主播，而且每个主播都有自己的画面和声音，但对于 CDN 观众来说，他们只需要一路直播流， 所以您需要将多路音视频流混成一路标准的直播流，这就需要混流转码。
  ///
  /// 当您调用 setMixTranscodingConfig() 接口时，SDK 会向腾讯云的转码服务器发送一条指令，目的是将房间里的多路音视频流混合为一路, 您可以通过 mixUsers 参数来调整每一路画面的位置，以及是否只混合声音，也可以通过 videoWidth、videoHeight、videoBitrate 等参数控制混合音视频流的编码参数。
  ///
  /// 参考文档：[云端混流转码](https://cloud.tencent.com/document/product/647/16827)。
  ///
  /// 参数：
  ///
  /// config	请参考 trtc_cloud.def.dart 中关于 TRTCTranscodingConfig 的介绍。如果传入 null 则取消云端混流转码。
  Future<void> setMixTranscodingConfig(TRTCTranscodingConfig? config) {
    if (kIsWeb) {
      return _channel.invokeMethod('setMixTranscodingConfig', jsonEncode(config));
    }
    return _channel.invokeMethod('setMixTranscodingConfig', {
      "config": jsonEncode(config),
    });
  }

  /// 暂停/恢复推送本地的视频数据。
  ///
  /// 当暂停推送本地视频后，房间里的其它成员将会收到 onUserVideoAvailable(userId, false) 回调通知 当恢复推送本地视频后，房间里的其它成员将会收到 onUserVideoAvailable(userId, true) 回调通知
  ///
  /// 参数：
  ///
  /// mute true：屏蔽；false：开启，默认值：false。
  Future<void> muteLocalVideo(bool mute) {
    return _channel.invokeMethod('muteLocalVideo', {
      "mute": mute,
    });
  }

  /// 设置暂停推送本地视频时要推送的图片
  ///
  /// 当暂停推送本地视频后，会继续推送该接口设置的图片
  ///
  /// 参数：
  ///
  /// assetUrl可以为flutter中定义的asset资源地址如'images/watermark_img.png'，也可以为网络图片地址
  ///
  /// fps	设置推送图片帧率，最小值为5，最大值为20，默认10。
  Future<int?> setVideoMuteImage(String? assetUrl, int fps) async {
    String? imageUrl = assetUrl;
    String type = 'network'; //默认为网络图片
    if (assetUrl != null && assetUrl.indexOf('http') != 0) {
      type = 'local';
    }
    return _channel.invokeMethod('setVideoMuteImage', {"imageUrl": imageUrl, "type": type, "fps": fps});
  }

  /// 开启本地视频的预览画面
  ///
  /// 当开始渲染首帧摄像头画面时，您会收到 TRTCCloudListener 中的 onFirstVideoFrame(null) 回调。
  ///
  /// 参数：
  ///
  /// frontCamera	true：前置摄像头；false：后置摄像头
  ///
  /// viewId TRTCCloudVideoView生成的viewId
  Future<void> startLocalPreview(bool frontCamera, int? viewId) {
    if (viewId == null) {
      return _channel.invokeMethod('startLocalPreview', {"isFront": frontCamera});
    } else {
      return TRTCCloudVideoViewController(viewId).startLocalPreview(frontCamera);
    }
  }

  /// 更新本地视频预览画面的窗口
  ///
  /// 注意：当viewType为TRTC_VideoView_TextureView时安卓才有效
  ///
  /// 参数：
  ///
  /// viewId	承载视频画面的控件
  Future<void> updateLocalView(viewId) {
    return TRTCCloudVideoViewController(viewId).updateLocalView(viewId);
  }

  /// 更新远端视频画面的窗口
  ///
  /// 注意：当viewType为TRTC_VideoView_TextureView时安卓才有效
  ///
  /// 参数：
  ///
  /// viewId	承载视频画面的控件
  ///
  /// userId 指定远端用户的 userId
  ///
  /// streamType 指定要观看 userId 的视频流类型：
  Future<void> updateRemoteView(viewId, streamType, userId) {
    return TRTCCloudVideoViewController(viewId).updateRemoteView(viewId, streamType, userId);
  }

  /// 停止本地视频采集及预览。
  Future<void> stopLocalPreview() {
    return _channel.invokeMethod('stopLocalPreview');
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
  ///
  /// viewId TRTCCloudVideoView生成的viewId
  Future<void> startRemoteView(String userId, int streamType, int? viewId) {
    if (viewId == null) {
      return _channel.invokeMethod('startRemoteView', {"userId": userId, "streamType": streamType});
    } else {
      return TRTCCloudVideoViewController(viewId).startRemoteView(userId, streamType);
    }
  }

  /// 停止显示远端视频画面，同时不再拉取该远端用户的视频数据流。
  ///
  /// 指定要停止观看的 userId 的视频流类型
  ///
  /// 参数：
  ///
  /// userId：用户Id
  ///
  /// streamType：
  ///
  ///* 高清大画面：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG
  ///* 低清大画面：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SMALL
  ///* 辅流（屏幕分享）：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SUB
  Future<void> stopRemoteView(String userId, int streamType) {
    return _channel.invokeMethod('stopRemoteView', {"userId": userId, "streamType": streamType});
  }

  /// 停止显示所有远端视频画面，同时不再拉取远端用户的视频数据流。
  ///
  /// 注意：如果有屏幕分享的画面在显示，则屏幕分享的画面也会一并被关闭
  Future<void> stopAllRemoteView() {
    return _channel.invokeMethod('stopAllRemoteView');
  }

  /// 暂停/恢复接收指定的远端视频流。
  ///
  /// 该接口仅暂停/恢复接收指定的远端用户的视频流，但并不释放显示资源，所以如果暂停，视频画面会冻屏在 mute 前的最后一帧。
  ///
  /// 参数：
  ///
  /// userId	对方的用户标识
  ///
  /// mute	是否暂停接收
  Future<void> muteRemoteVideoStream(String userId, bool mute) {
    return _channel.invokeMethod('muteRemoteVideoStream', {
      "userId": userId,
      "mute": mute,
    });
  }

  /// 暂停/恢复接收所有远端视频流。
  ///
  /// 该接口仅暂停/恢复接收所有远端用户的视频流，但并不释放显示资源，所以如果暂停，视频画面会冻屏在 mute 前的最后一帧。
  ///
  /// 参数：
  ///
  /// mute	是否暂停接收
  Future<void> muteAllRemoteVideoStreams(bool mute) {
    return _channel.invokeMethod('muteAllRemoteVideoStreams', {
      "mute": mute,
    });
  }

  /// 设置视频编码器相关参数。
  ///
  /// 该设置决定了远端用户看到的画面质量（同时也是云端录制出的视频文件的画面质量）
  ///
  /// 参数：
  ///
  /// param	视频编码参数，详情请参考 TRTCVideoEncParam 定义
  Future<void> setVideoEncoderParam(TRTCVideoEncParam param) {
    if (kIsWeb) {
      return _channel.invokeMethod('setVideoEncoderParam', jsonEncode(param));
    }
    return _channel.invokeMethod('setVideoEncoderParam', {
      "param": jsonEncode(param),
    });
  }

  /// 设置网络流控相关参数。
  ///
  /// 该设置决定 SDK 在各种网络环境下的调控策略（例如弱网下选择“保清晰”或“保流畅”）
  ///
  /// 参数：
  ///
  /// param	网络流控参数，详情请参考 trtc_cloud.def.dart 中的 TRTCNetworkQosParam 定义
  Future<void> setNetworkQosParam(TRTCNetworkQosParam param) {
    return _channel.invokeMethod('setNetworkQosParam', {"param": jsonEncode(param)});
  }

  /// 设置本地图像的渲染模式。
  ///
  /// 参数：
  ///
  /// renderParams 渲染参数（平铺模式、旋转角度、左右镜像等)，详情请参考 trtc_cloud.def.dart 中的 TRTCRenderParams参数定义
  Future<void> setLocalRenderParams(TRTCRenderParams renderParams) {
    return _channel.invokeMethod('setLocalRenderParams', {
      "param": jsonEncode(renderParams),
    });
  }

  /// 设置远端图像相关参数。
  ///
  /// 参数：
  ///
  /// userId 用户 ID
  ///
  /// streamType 视频流类型：
  ///* 高清大画面：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG
  ///* 低清大画面：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SMALL
  ///* 辅流（屏幕分享）：TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SUB
  ///
  /// renderParams 渲染参数（平铺模式、旋转角度、左右镜像等)，详情请参考 trtc_cloud.def.dart 中的 TRTCRemoteRenderParams参数定义
  Future<void> setRemoteRenderParams(String userId, int streamType, TRTCRenderParams renderParams) {
    return _channel.invokeMethod('setRemoteRenderParams', {
      "userId": userId,
      "streamType": streamType,
      "param": jsonEncode(renderParams),
    });
  }

  /// 设置视频编码输出的画面方向，即设置远端用户观看到的和服务器录制的画面方向。
  ///
  /// 当用户的手机或者 Android Pad 做了一个180度旋转时，由于摄像头的采集方向没有变，所以另一边的用户看到的画面是上下颠倒的， 在这种情况下，您可以通过该接口将 SDK 输出到对方的画面旋转180度，这样可以可以确保对方看到的画面依然正常。
  ///
  /// 注意: sdk会默认开启重力感应，开启重力感应后设置无效，关闭重力感应设置该接口才会生效
  ///
  /// 参数：
  ///
  /// rotation	顺时针旋转角度，目前仅支持0度和180度两个角度：
  ///
  /// TRTCCloudDef.TRTC_VIDEO_ROTATION_0，不旋转（默认值）; TRTCCloudDef.TRTC_VIDEO_ROTATION_180，顺时针旋转180度。
  Future<void> setVideoEncoderRotation(int rotation) {
    return _channel.invokeMethod('setVideoEncoderRotation', {
      "rotation": rotation,
    });
  }

  /// 设置编码器输出的画面镜像模式。
  ///
  /// 该接口不改变本地摄像头的预览画面，但会改变另一端用户看到的（以及服务器录制下来的）画面效果。
  ///
  /// 参数：
  ///
  /// mirror	true：镜像；false：不镜像；默认值：false
  Future<void> setVideoEncoderMirror(bool mirror) {
    return _channel.invokeMethod('setVideoEncoderMirror', {
      "mirror": mirror,
    });
  }

  /// 设置重力感应的适应模式。
  ///
  /// 参数：
  ///
  /// mode	重力感应模式：
  /// TRTCCloudDef.TRTC_GSENSOR_MODE_DISABLE ：关闭重力感应
  ///
  /// TRTCCloudDef.TRTC_GSENSOR_MODE_UIAUTOLAYOUT：开启重力感应，但是 SDK 不会根据陀螺仪自动调整本地 View 的画面方向， 而是交给 Android 系统的自动排布功能（这需要您的 App 界面开启了重力感应适配选项）
  ///
  /// TRTCCloudDef.TRTC_GSENSOR_MODE_UIFIXLAYOUT ：开启重力感应，并且 SDK 会根据陀螺仪自动调整本地 View 的画面方向。
  Future<void> setGSensorMode(int mode) {
    return _channel.invokeMethod('setGSensorMode', {
      "mode": mode,
    });
  }

  /// 开启大小画面双路编码模式。
  ///
  /// 如果当前用户是房间中的主要角色（例如主播、老师、主持人等），并且使用 PC 或者 Mac 环境，可以开启该模式。 开启该模式后，当前用户会同时输出【高清】和【低清】两路视频流（但只有一路音频流）。 对于开启该模式的当前用户，会占用更多的网络带宽，并且会更加消耗 CPU 计算资源。
  ///
  /// 对于同一房间的远程观众而言：
  ///
  ///* 如果下行网络很好，可以选择观看【高清】画面
  ///* 如果下行网络较差，可以选择观看【低清】画面
  ///
  /// 注意：双路编码开启后，会消耗更多的 CPU 和 网络带宽，所以对于 iMac、Windows 或者高性能 Pad 可以考虑开启，但请不要在手机端开启。
  ///
  /// 参数：
  ///
  /// enable	是否开启小画面编码，默认值：false
  ///
  /// smallVideoEncParam	小流的视频参数，详情请参考 TRTCVideoEncParam 定义
  ///
  /// 返回：
  ///
  /// 0：成功；-1：大画面已经是最低画质
  Future<int?> enableEncSmallVideoStream(
      bool enable, // 是否开启小画面编码，默认值：false。
      TRTCVideoEncParam smallVideoEncParam // 小流的视频参数。
      ) {
    return _channel.invokeMethod('enableEncSmallVideoStream', {
      "enable": enable,
      "smallVideoEncParam": jsonEncode(smallVideoEncParam),
    });
  }

  /// 选定观看指定 uid 的大画面或小画面。
  ///
  /// 注意：
  ///* 此功能需要该 uid 通过 enableEncSmallVideoStream 提前开启双路编码模式。 如果该 uid 没有开启双路编码模式，则此操作将无任何反应。
  ///* 在不通过此接口进行设置的情况下，startRemoteView 默认观看的画面为大画面。
  ///
  /// 参数：
  ///
  /// userId	用户 ID
  ///
  /// streamType	视频流类型，即选择看大画面(TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG)或小画面(TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SMALL)，默认为大画面。
  Future<int?> setRemoteVideoStreamType(
      String userId, // 用户ID
      int streamType // 视频流类型，即选择看大画面或小画面，默认为大画面。
      ) {
    return _channel.invokeMethod('setRemoteVideoStreamType', {
      "userId": userId,
      "streamType": streamType,
    });
  }

  /// 视频画面截图。
  ///
  /// 截取本地、远程主路和远端辅流的视频画面。
  ///
  /// 参数：
  ///
  /// userId	用户 ID，null 表示截取本地视频画面，本地仅支持摄像头画面（TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG）的截取。
  ///
  /// streamType	视频流类型，支持摄像头画面（TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG）和 屏幕分享画面（TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SUB）。
  ///
  /// path 该路径需精确到文件名及格式后缀，格式后缀决定图片的格式，目前支持的格式有 png/jpg/webp。 例如，指定路径为 path/to/test.png，则会生成一个 png 格式的图片文件。 请指定一个有读写权限的合法路径，否则图片文件无法生成。
  Future<void> snapshotVideo(String? userId, int streamType, String path) {
    return _channel.invokeMethod('snapshotVideo', {"userId": userId, "streamType": streamType, "path": path});
  }

  /// 开启本地音频的采集和上行,并设置音频质量。
  ///
  /// 该函数会启动麦克风采集，并将音频数据传输给房间里的其他用户。 SDK 不会默认开启本地音频采集和上行，您需要调用该函数开启，否则房间里的其他用户将无法听到您的声音。
  ///
  /// 主播端的音质越高，观众端的听感越好，但传输所依赖的带宽也就越高，在带宽有限的场景下也更容易出现卡顿。
  Future<void> startLocalAudio(int quality) {
    return _channel.invokeMethod('startLocalAudio', {"quality": quality});
  }

  /// 关闭本地音频的采集和上行。
  ///
  /// 当关闭本地音频的采集和上行，房间里的其它成员会收到 onUserAudioAvailable(false) 回调通知。
  Future<void> stopLocalAudio() {
    return _channel.invokeMethod('stopLocalAudio');
  }

  /// 静音/取消静音本地的音频。
  ///
  /// 当静音本地音频后，房间里的其它成员会收到 onUserAudioAvailable(userId, false) 回调通知。 当取消静音本地音频后，房间里的其它成员会收到 onUserAudioAvailable(userId, true) 回调通知。
  ///
  /// 与 stopLocalAudio 不同之处在于，muteLocalAudio(true) 并不会停止发送音视频数据，而是继续发送码率极低的静音包。 由于 MP4 等视频文件格式，对于音频的连续性是要求很高的，使用 stopLocalAudio 会导致录制出的 MP4 不易播放。 因此在对录制质量要求很高的场景中，建议选择 muteLocalAudio，从而录制出兼容性更好的 MP4 文件。
  ///
  /// 参数：
  ///
  /// mute	true：静音；false：取消静音
  Future<void> muteLocalAudio(bool mute) {
    return _channel.invokeMethod('muteLocalAudio', {
      "mute": mute,
    });
  }

  /// 静音/取消静音指定的远端用户的声音。
  ///
  /// 参数：
  ///
  /// userId	对方的用户 ID
  ///
  /// mute	true：静音；false：取消静音
  ///
  /// 注意：静音时会停止接收该用户的远端音频流并停止播放，取消静音时会自动拉取该用户的远端音频流并进行播放。
  Future<void> muteRemoteAudio(String userId, bool mute) {
    return _channel.invokeMethod('muteRemoteAudio', {
      "userId": userId,
      "mute": mute,
    });
  }

  /// 静音/取消静音所有用户的声音。
  ///
  /// 参数：
  ///
  /// mute	true：静音；false：取消静音
  ///
  /// 注意：静音时会停止接收所有用户的远端音频流并停止播放，取消静音时会自动拉取所有用户的远端音频流并进行播放。
  Future<void> muteAllRemoteAudio(bool mute) {
    return _channel.invokeMethod('muteAllRemoteAudio', {
      "mute": mute,
    });
  }

  /// 设置某个远程用户的播放音量
  ///
  /// 参数：
  ///
  /// userId	远程用户 ID
  ///
  /// volume	音量大小，取值0 - 100
  Future<void> setRemoteAudioVolume(String userId, int volume) {
    return _channel.invokeMethod('setRemoteAudioVolume', {
      "userId": userId,
      "volume": volume,
    });
  }

  /// 设置 SDK 采集音量。
  ///
  /// 参数：
  ///
  /// volume	音量大小，取值0 - 100
  Future<void> setAudioCaptureVolume(int volume) {
    return _channel.invokeMethod('setAudioCaptureVolume', {
      "volume": volume,
    });
  }

  /// 获取 SDK 采集音量。
  Future<int?> getAudioCaptureVolume() {
    return _channel.invokeMethod('getAudioCaptureVolume');
  }

  /// 设置 SDK 播放音量。
  ///
  /// 该函数会控制最终交给系统播放的声音音量，会影响录制本地音频文件的音量大小，但不会影响耳返的音量。
  ///
  /// 参数：
  ///
  /// volume	音量大小，取值0 - 100
  Future<void> setAudioPlayoutVolume(int volume) {
    return _channel.invokeMethod('setAudioPlayoutVolume', {
      "volume": volume,
    });
  }

  /// 获取 SDK 播放音量
  Future<int?> getAudioPlayoutVolume() {
    return _channel.invokeMethod('getAudioPlayoutVolume');
  }

  /// 启用音量大小提示。
  ///
  /// 开启后会在 onUserVoiceVolume 中获取到 SDK 对音量大小值的评估。如需打开此功能，请在 startLocalAudio() 之前调用。
  ///
  /// 参数：
  ///
  /// intervalMs	决定了 onUserVoiceVolume 回调的触发间隔，单位为ms，最小间隔为100ms，如果小于等于0则会关闭回调，建议设置为300ms；详细的回调规则请参考 onUserVoiceVolume 的注释说明
  Future<void> enableAudioVolumeEvaluation(int intervalMs) {
    return _channel.invokeMethod('enableAudioVolumeEvaluation', {
      "intervalMs": intervalMs,
    });
  }

  /// 开始录音。
  ///
  /// 该方法调用后， SDK 会将通话过程中的所有音频（包括本地音频，远端音频，BGM 等）录制到一个文件里。 无论是否进房，调用该接口都生效。 如果调用 exitRoom 时还在录音，录音会自动停止。
  ///
  /// 参数：
  ///
  /// TRTCAudioRecordingParams	录音参数
  ///
  /// 返回：
  ///
  /// 0：成功；-1：录音已开始；-2：文件或目录创建失败；-3：后缀指定的音频格式不支持; -1001:参数错误
  Future<int?> startAudioRecording(TRTCAudioRecordingParams param) async {
    return _channel.invokeMethod('startAudioRecording', {
      "param": jsonEncode(param),
    });
  }

  /// 停止录音。
  ///
  /// 如果调用 exitRoom 时还在录音，录音会自动停止。
  Future<void> stopAudioRecording() {
    return _channel.invokeMethod('stopAudioRecording');
  }

  /// 开启本地媒体录制
  ///
  /// 开启后把直播过程中的音视和视频内容录制到本地的一个文件中。
  ///
  /// 参数：
  ///
  /// params	录制参数，请参考 TRTCLocalRecordingParams
  Future<void> startLocalRecording(TRTCLocalRecordingParams param) async {
    return _channel.invokeMethod('startLocalRecording', {
      "param": jsonEncode(param),
    });
  }

  /// 停止本地媒体录制
  ///
  /// 如果录制任务在退出房间前尚未通过本接口停止，则退出房间后录音任务会自动被停止。
  Future<void> stopLocalRecording() {
    return _channel.invokeMethod('stopLocalRecording');
  }

  /// 获取设备管理模块。
  TXDeviceManager getDeviceManager() {
    _channel.invokeMethod('getDeviceManager');
    return new TXDeviceManager(_channel);
  }

  /// 获取美颜管理对象。
  TXBeautyManager getBeautyManager() {
    _channel.invokeMethod('getBeautyManager');
    return new TXBeautyManager(_channel);
  }

  /// 添加水印
  ///
  /// 水印的位置是通过 x, y, width 来指定的
  ///* x：水印的坐标，取值范围为0 - 1的浮点数。
  ///* y：水印的坐标，取值范围为0 - 1的浮点数。
  ///* width：水印的宽度，取值范围为0 - 1的浮点数。
  ///
  /// 举例：如果当前编码分辨率是540 × 960，(x, y, width) 设置为（0.1, 0.1, 0.2） 那么：水印的左上坐标点就是 (540 × 0.1， 960 × 0.1)，也就是 (54, 96)，水印的宽度是 540 × 0.2 = 108px，高度自动计算。
  ///
  /// 参数：
  ///
  /// assetUrl可以为flutter中定义的asset资源地址如'images/watermark_img.png'，也可以为网络图片地址
  ///
  /// streamType	如果要给屏幕分享的一路也设置水印，需要调用两次的 setWatermark，请参考 TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG
  ///
  /// x	归一化水印位置的 X 轴坐标，取值[0,1]
  ///
  /// y	归一化水印位置的 Y 轴坐标，取值[0,1]
  ///
  /// width	归一化水印宽度，取值[0,1]
  Future<void> setWatermark(String assetUrl, int streamType, double x, double y, double width) async {
    String imageUrl = assetUrl;
    String type = 'network'; //默认为网络图片
    if (assetUrl.indexOf('http') != 0) {
      type = 'local';
    }
    return _channel.invokeMethod('setWatermark', {
      "type": type,
      "imageUrl": imageUrl,
      "streamType": streamType,
      "x": x.toString(),
      "y": y.toString(),
      "width": width.toString()
    });
  }

  // 开始桌面端屏幕分享
  ///
  /// 参数：
  ///
  /// 屏幕分享使用的线路，可以设置为主路（TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_BIG）或者辅路（TRTCCloudDef.TRTC_VIDEO_STREAM_TYPE_SUB）
  ///
  /// encParams	设置屏幕分享时的编码参数，推荐采用上述推荐配置，如果您指定 encParams 为 nil，则使用您调用 startScreenCapture 之前的编码参数设置。
  ///
  /// appGroup	该参数仅仅在ios端有效，Android端不需要关注这个参数。该参数是主 App 与 Broadcast 共享的 Application Group Identifier。
  ///
  /// 在ios下如果appGroup为空的话，将只能变为应用内的屏幕分享，并且只有在iOS 13.0 及以上的有效
  ///
  /// 在web下需要shareUserId 和 shareUserSig，其他参数无效
  ///
  /// [屏幕录制](https://cloud.tencent.com/document/product/647/45751)
  Future<void> startScreenCapture(
    int streamType,
    TRTCVideoEncParam encParams, {
    String shareUserId = '',
    String shareUserSig = '',
    String appGroup = '',
  }) {
    if (kIsWeb) {
      return _channel.invokeMethod('startScreenCapture', {
        "shareUserId": shareUserId,
        "shareUserSig": shareUserSig,
        "streamType": streamType,
      });
    }
    if (!kIsWeb && Platform.isAndroid) {
      return _channel.invokeMethod('startScreenCapture', {
        "encParams": jsonEncode(encParams),
        "streamType": streamType,
      });
    }
    if (!kIsWeb && Platform.isIOS && appGroup != '') {
      return _channel.invokeMethod('startScreenCaptureByReplaykit', {
        "encParams": jsonEncode(encParams),
        "appGroup": appGroup,
        "streamType": streamType,
      });
    } else if (!kIsWeb && Platform.isIOS && appGroup == '') {
      return _channel.invokeMethod('startScreenCaptureInApp', {
        "encParams": jsonEncode(encParams),
        "streamType": streamType,
      });
    }
    return _channel.invokeMethod('startScreenCapture', {
      "streamType": streamType,
      "encParams": jsonEncode(encParams),
    });
  }

  /// 停止屏幕采集
  Future<void> stopScreenCapture() {
    return _channel.invokeMethod('stopScreenCapture');
  }

  /// 暂停屏幕分享
  Future<void> pauseScreenCapture() {
    return _channel.invokeMethod('pauseScreenCapture');
  }

  /// 恢复屏幕分享
  Future<void> resumeScreenCapture() {
    return _channel.invokeMethod('resumeScreenCapture');
  }

  /// 获取音效管理类 TXAudioEffectManager。
  TXAudioEffectManager getAudioEffectManager() {
    _channel.invokeMethod('getAudioEffectManager');
    return new TXAudioEffectManager(_channel);
  }

  /// 发送自定义消息给房间内所有用户
  ///
  /// 该接口可以借助音视频数据通道向当前房间里的其他用户广播您自定义的数据，但因为复用了音视频数据通道， 请务必严格控制自定义消息的发送频率和消息体的大小，否则会影响音视频数据的质量控制逻辑，造成不确定性的问题。
  ///
  /// 参数：
  ///
  /// cmdID	消息 ID，取值范围为1 - 10
  ///
  /// data	待发送的消息，最大支持1KB（1000字节）的数据大小。
  ///
  /// reliable	是否可靠发送，可靠发送的代价是会引入一定的延时，因为接收端要暂存一段时间的数据来等待重传
  ///
  /// ordered	是否要求有序，即是否要求接收端接收的数据顺序和发送端发送的顺序一致，这会带来一定的接收延时，因为在接收端需要暂存并排序这些消息。
  ///
  /// 返回：
  ///
  /// true：消息已经发出；false：消息发送失败
  ///
  /// 本接口有以下限制：
  ///
  /// * 发送消息到房间内所有用户（暂时不支持 Web/小程序端），每秒最多能发送30条消息。
  ///
  /// * 每个包最大为1KB，超过则很有可能会被中间路由器或者服务器丢弃。
  ///
  /// * 每个客户端每秒最多能发送总计8KB数据。
  ///
  /// * 将 reliable 和 ordered 同时设置为 true 或 false，暂不支持交叉设置。
  ///
  /// * 强烈建议不同类型的消息使用不同的 cmdID，这样可以在要求有序的情况下减小消息时延。
  Future<bool?> sendCustomCmdMsg(int cmdID, String data, bool reliable, bool ordered) {
    return _channel.invokeMethod('sendCustomCmdMsg', {
      "cmdID": cmdID,
      "data": data,
      "reliable": reliable,
      "ordered": ordered,
    });
  }

  /// 将小数据量的自定义数据嵌入视频帧中
  ///
  /// 与 sendCustomCmdMsg 的原理不同，sendSEIMsg 是将数据直接塞入视频数据头中。因此，即使视频帧被旁路到了直播 CDN 上， 这些数据也会一直存在。由于需要把数据嵌入视频帧中，建议尽量控制数据大小，推荐使用几个字节大小的数据。
  ///
  /// 最常见的用法是把自定义的时间戳（timstamp）用 sendSEIMsg 嵌入视频帧中，这种方案的最大好处就是可以实现消息和画面的完美对齐。
  ///
  /// 参数：
  ///
  /// data	待发送的数据，最大支持1kb（1000字节）的数据大小。
  ///
  /// repeatCount	发送数据次数
  ///
  /// 返回：
  ///
  /// true：消息已通过限制，等待后续视频帧发送；false：消息被限制发送
  ///
  /// 本接口有以下限制：
  ///
  /// 数据在接口调用完后不会被即时发送出去，而是从下一帧视频帧开始带在视频帧中发送。
  ///
  /// 发送消息到房间内所有用户，每秒最多能发送30条消息（与 sendCustomCmdMsg 共享限制）。
  ///
  /// 每个包最大为1KB，若发送大量数据，会导致视频码率增大，可能导致视频画质下降甚至卡顿（与 sendCustomCmdMsg 共享限制）。
  ///
  /// 每个客户端每秒最多能发送总计8KB数据（与 sendCustomCmdMsg 共享限制）。
  ///
  /// 若指定多次发送（repeatCount > 1），则数据会被带在后续的连续 repeatCount 个视频帧中发送出去，同样会导致视频码率增大。
  ///
  /// 如果 repeatCount > 1，多次发送，接收消息 onRecvSEIMsg 回调也可能会收到多次相同的消息，需要去重。
  Future<bool?> sendSEIMsg(String data, int repeatCount) {
    return _channel.invokeMethod('sendSEIMsg', {"data": data, "repeatCount": repeatCount});
  }

  /// 开始进行网络测速（视频通话期间请勿测试，以免影响通话质量）
  ///
  /// 测速结果将会用于优化 SDK 接下来的服务器选择策略，因此推荐您在用户首次通话前先进行一次测速，这将有助于我们选择最佳的服务器。 同时，如果测试结果非常不理想，您可以通过醒目的 UI 提示用户选择更好的网络。 测试结果通过 TRTCCloudListener.onSpeedTest 回调出来。
  ///
  /// 注意：测速过程将产生少量的基础服务费用，详见 [计费概述 > 基础服务](https://cloud.tencent.com/document/product/647/17157#.E5.9F.BA.E7.A1.80.E6.9C.8D.E5.8A.A1) 文档说明。
  ///
  /// 参数：
  ///
  /// sdkAppId	应用标识
  ///
  /// userId	用户标识
  ///
  /// userSig	用户签名
  Future<void> startSpeedTest(int sdkAppId, String userId, String userSig) {
    return _channel.invokeMethod('startSpeedTest', {
      "sdkAppId": sdkAppId,
      "userId": userId,
      "userSig": userSig,
    });
  }

  /// 停止服务器测速。
  Future<void> stopSpeedTest() {
    return _channel.invokeMethod('stopSpeedTest');
  }

  /// 获取 SDK 版本信息
  Future<String?> getSDKVersion() {
    return _channel.invokeMethod('getSDKVersion');
  }

  /// 设置 Log 输出级别
  ///
  /// 参数：
  ///
  /// level	请参见 TRTC_LOG_LEVEL，默认值：TRTCCloudDef.TRTC_LOG_LEVEL_NULL
  Future<void> setLogLevel(int level) {
    return _channel.invokeMethod('setLogLevel', {"level": level});
  }

  /// 启用或禁用控制台日志打印
  ///
  /// 参数：
  ///
  /// enabled	指定是否启用，默认为禁止状态
  Future<void> setConsoleEnabled(bool enabled) {
    return _channel.invokeMethod('setConsoleEnabled', {
      "enabled": enabled,
    });
  }

  /// 启用或禁用 Log 的本地压缩。
  ///
  /// 开启压缩后，log　存储体积明显减小，但需要腾讯云提供的 Python 脚本解压后才能阅读。 禁用压缩后，log　采用明文存储，可以直接用记事本打开阅读，但占用空间较大。
  ///
  /// 参数：
  ///
  /// enabled	指定是否启用，默认为启用状态
  Future<void> setLogCompressEnabled(bool enabled) {
    return _channel.invokeMethod('setLogCompressEnabled', {
      "enabled": enabled,
    });
  }

  /// 修改日志保存路径
  ///
  /// 日志文件默认保存在 /app私有目录/files/log/tencent/liteav/ 下，如需修改, 必须在所有方法前调用，并且保证目录存在及应用有目录的读写权限。
  ///
  /// 参数：
  ///
  /// path 存储日志路径
  Future<void> setLogDirPath(String path) {
    return _channel.invokeMethod('setLogDirPath', {
      "path": path,
    });
  }

  /// 显示仪表盘
  ///
  /// 仪表盘是状态统计和事件消息浮层　view，方便调试。
  ///
  /// 参数：
  ///
  /// showType	0：不显示；1：显示精简版；2：显示全量版，默认为不显示
  Future<void> showDebugView(int showType) {
    return _channel.invokeMethod('showDebugView', {
      "mode": showType,
    });
  }

  /// 调用实验性 API 接口
  ///
  /// 注意：该接口用于调用一些实验性功能
  ///
  /// 参数：jsonStr	接口及参数描述的 JSON 字符串
  Future<void> callExperimentalAPI(String jsonStr) {
    return _channel.invokeMethod('callExperimentalAPI', {
      "jsonStr": jsonStr,
    });
  }
}
