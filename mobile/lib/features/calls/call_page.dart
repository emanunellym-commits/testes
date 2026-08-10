import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/network/socket_service.dart';

class CallPage extends StatefulWidget {
  const CallPage({
    super.key,
    required this.conversationId,
    required this.peerName,
    required this.callId,
    required this.video,
    required this.isCaller,
  });

  final String conversationId;
  final String peerName;
  final String callId;
  final bool video;
  final bool isCaller;

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  final localRenderer = RTCVideoRenderer();
  final remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? pc;
  MediaStream? localStream;
  bool mic = true;
  bool camera = true;
  bool connected = false;
  String status = 'Conectando...';
  Timer? durationTimer;
  int seconds = 0;

  final socketService = SocketService.instance;

  Map<String, dynamic> get base => {
        'conversationId': widget.conversationId,
        'callId': widget.callId,
        'video': widget.video,
      };

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await localRenderer.initialize();
    await remoteRenderer.initialize();
    final socket = await socketService.connect();
    socketService.join(widget.conversationId);

    socket.on('call.accept', onAccepted);
    socket.on('call.reject', onRejected);
    socket.on('call.offer', onOffer);
    socket.on('call.answer', onAnswer);
    socket.on('call.ice', onIce);
    socket.on('call.end', onEnded);

    await setupPeer();

    if (widget.isCaller) {
      socket.emit('call.invite', base);
      setState(() => status = 'Chamando ${widget.peerName}...');
    } else {
      socket.emit('call.accept', base);
      setState(() => status = 'Atendendo...');
    }
  }

  Future<void> setupPeer() async {
    localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });
    localRenderer.srcObject = localStream;

    pc = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
      'sdpSemantics': 'unified-plan',
    });

    for (final track in localStream!.getTracks()) {
      await pc!.addTrack(track, localStream!);
    }

    pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
        if (mounted) setState(() {});
      }
    };

    pc!.onIceCandidate = (candidate) {
      if (candidate.candidate == null) return;
      socketService.socket?.emit('call.ice', {
        ...base,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc!.onConnectionState = (state) {
      if (!mounted) return;
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() {
          connected = true;
          status = 'Conectado';
        });
        startDuration();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        setState(() => status = 'Falha na conexão');
      }
    };
  }

  bool sameCall(dynamic data) =>
      data is Map &&
      data['conversationId'] == widget.conversationId &&
      data['callId'] == widget.callId;

  Future<void> onAccepted(dynamic data) async {
    if (!sameCall(data) || !widget.isCaller) return;
    final offer = await pc!.createOffer();
    await pc!.setLocalDescription(offer);
    socketService.socket?.emit('call.offer', {
      ...base,
      'sdp': offer.sdp,
      'type': offer.type,
    });
    if (mounted) setState(() => status = 'Conectando chamada...');
  }

  void onRejected(dynamic data) {
    if (!sameCall(data)) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chamada recusada.')),
      );
      Navigator.pop(context);
    }
  }

  Future<void> onOffer(dynamic data) async {
    if (!sameCall(data) || widget.isCaller) return;
    await pc!.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
    final answer = await pc!.createAnswer();
    await pc!.setLocalDescription(answer);
    socketService.socket?.emit('call.answer', {
      ...base,
      'sdp': answer.sdp,
      'type': answer.type,
    });
  }

  Future<void> onAnswer(dynamic data) async {
    if (!sameCall(data) || !widget.isCaller) return;
    await pc!.setRemoteDescription(RTCSessionDescription(data['sdp'], data['type']));
  }

  Future<void> onIce(dynamic data) async {
    if (!sameCall(data)) return;
    final candidate = data['candidate'];
    if (candidate == null) return;
    await pc?.addCandidate(RTCIceCandidate(
      candidate,
      data['sdpMid'],
      data['sdpMLineIndex'],
    ));
  }

  void onEnded(dynamic data) {
    if (!sameCall(data)) return;
    if (mounted) Navigator.pop(context);
  }

  void startDuration() {
    durationTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => seconds++);
    });
  }

  String get duration {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void toggleMic() {
    mic = !mic;
    for (final track in localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = mic;
    }
    setState(() {});
  }

  void toggleCamera() {
    camera = !camera;
    for (final track in localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = camera;
    }
    setState(() {});
  }

  Future<void> switchCamera() async {
    final tracks = localStream?.getVideoTracks() ?? [];
    if (tracks.isNotEmpty) await Helper.switchCamera(tracks.first);
  }

  Future<void> hangup({bool notify = true}) async {
    if (notify) socketService.socket?.emit('call.end', base);
    durationTimer?.cancel();
    for (final track in localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      await track.stop();
    }
    await localStream?.dispose();
    await pc?.close();
    localRenderer.srcObject = null;
    remoteRenderer.srcObject = null;
    if (mounted) Navigator.pop(context);
  }

  void removeListeners() {
    final s = socketService.socket;
    s?.off('call.accept', onAccepted);
    s?.off('call.reject', onRejected);
    s?.off('call.offer', onOffer);
    s?.off('call.answer', onAnswer);
    s?.off('call.ice', onIce);
    s?.off('call.end', onEnded);
  }

  @override
  void dispose() {
    removeListeners();
    durationTimer?.cancel();
    for (final track in localStream?.getTracks() ?? <MediaStreamTrack>[]) {
      track.stop();
    }
    pc?.close();
    localRenderer.dispose();
    remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) hangup();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF03101E),
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.video
                    ? (remoteRenderer.srcObject != null
                        ? RTCVideoView(remoteRenderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
                        : const Center(child: Icon(Icons.person, size: 120, color: Colors.white24)))
                    : const Center(child: Icon(Icons.person, size: 140, color: Colors.white24)),
              ),
              if (widget.video && localRenderer.srcObject != null)
                Positioned(
                  top: 24,
                  right: 18,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 110,
                      height: 160,
                      child: RTCVideoView(localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
                    ),
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                top: 48,
                child: Column(
                  children: [
                    Text(widget.peerName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 7),
                    Text(connected ? duration : status, style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 30,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .48),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CallButton(icon: mic ? Icons.mic : Icons.mic_off, onTap: toggleMic),
                      if (widget.video) _CallButton(icon: camera ? Icons.videocam : Icons.videocam_off, onTap: toggleCamera),
                      if (widget.video) _CallButton(icon: Icons.cameraswitch_rounded, onTap: switchCamera),
                      _CallButton(icon: Icons.call_end, danger: true, onTap: () => hangup()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.icon, required this.onTap, this.danger = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: CircleAvatar(
        radius: 28,
        backgroundColor: danger ? Colors.redAccent : Colors.white24,
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
