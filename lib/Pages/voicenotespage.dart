import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceNotesPage extends StatefulWidget {
  const VoiceNotesPage({super.key});

  @override
  _VoiceNotesPageState createState() => _VoiceNotesPageState();
}

class _VoiceNotesPageState extends State<VoiceNotesPage> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  List<String> _wordHistory = [];
  bool _isRecording = false;

  final Color _bluePrimary = const Color(0xFF389ee8);
  final Color _blueSecondary = const Color(0xFF76dcfb);

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'notListening' && _isRecording) {
            // Immediate restart if stopped unexpectedly
            _startListening();
          }
        },
        onError: (error) {
          print('Speech recognition error: $error');
          // Handle potential errors
          setState(() {
            _isRecording = false;
          });
        },
      );
      setState(() {});
    } catch (e) {
      print('Speech initialization error: $e');
      setState(() {
        _speechEnabled = false;
      });
    }
  }

  void _startListening() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(minutes: 30),
        pauseFor: const Duration(seconds: 10), // Reduced pause time
        partialResults: true, // Capture partial results
        cancelOnError: false,
        listenMode: ListenMode.confirmation,
      );
      
      setState(() {
        _isRecording = true;
        _lastWords = ''; // Clear previous words
      });
    } catch (e) {
      print('Start listening error: $e');
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _stopListening() async {
    try {
      await _speechToText.stop();
      setState(() {
        _isRecording = false;
        if (_lastWords.isNotEmpty) {
          _wordHistory.add(_lastWords);
        }
      });
    } catch (e) {
      print('Stop listening error: $e');
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      
      // Optionally add partial results
      if (result.finalResult) {
        _wordHistory.add(result.recognizedWords);
      }
    });
  }

  void _toggleRecording() {
    if (!_speechToText.isListening) {
      _startListening();
    } else {
      _stopListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    // [Previous build method remains the same]
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Voice Notes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: _bluePrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              _blueSecondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: _bluePrimary.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  _lastWords.isNotEmpty
                      ? _lastWords
                      : (_isRecording ? 'Listening...' : 'Tap to Record'),
                  style: TextStyle(
                    fontSize: 18,
                    color: _bluePrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [Colors.red.withOpacity(0.8), Colors.redAccent]
                          : [_bluePrimary, _blueSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isRecording
                            ? Colors.red.withOpacity(0.5)
                            : _bluePrimary.withOpacity(0.5),
                        blurRadius: 25,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 100,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _speechEnabled
                    ? (_isRecording
                        ? 'Recording...'
                        : 'Tap microphone to start')
                    : 'Speech recognition not available',
                style: TextStyle(
                  fontSize: 18,
                  color: _bluePrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}