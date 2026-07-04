import 'package:flutter/material.dart';
import '../services/speech_service_disabled.dart';
import '../constants/app_constants.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onResult;
  final String? tooltip;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.tooltip,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FloatingActionButton(
            heroTag: "voice_fab",
            onPressed: _toggleListening,
            backgroundColor: _isListening 
                ? AppConstants.errorColor 
                : AppConstants.accentColor,
            tooltip: widget.tooltip ?? 'Voice Input',
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    final initialized = await _speechService.initialize();
    if (!initialized) {
      _showError('Microphone permission denied or speech recognition not available');
      return;
    }

    setState(() {
      _isListening = true;
    });

    _animationController.repeat(reverse: true);

    await _speechService.startListening(
      onResult: (result) {
        if (result.isNotEmpty) {
          widget.onResult(result);
          _stopListening();
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _speechService.stopListening();
    setState(() {
      _isListening = false;
    });
    _animationController.stop();
    _animationController.reset();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }
}