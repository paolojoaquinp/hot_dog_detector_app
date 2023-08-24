import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hot_dog_detector/constants.dart';
import 'package:hot_dog_detector/models/classifier.dart';
import 'package:hot_dog_detector/widgets/hot_dog_photo_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;


const _labelsFileName = 'assets/labels.txt';
const _modelFileName = 'models/model_unquant.tflite';

class HotDogRecongnizer extends StatefulWidget {
  const HotDogRecongnizer({super.key});

  @override
  State<HotDogRecongnizer> createState() => _HotDogRecongnizerState();
}

enum _ResultStatus {
  notStarted,
  notFound,
  found,
}

class _HotDogRecongnizerState extends State<HotDogRecongnizer> {
  File? _selectedImageFile;
  bool _isAnalyzing = false;
  final picker = ImagePicker();

  // Result
  _ResultStatus _resultStatus = _ResultStatus.notStarted;
  String _hotDogLabel = '';
  double _accuracy = 0.0;

  late Classifier? _classifier;

  @override
  void initState() {
    super.initState();
    _loadClassifier();
  }

  Future<void> _loadClassifier() async {
    debugPrint(
      'Start loading of Classifier with '
      'labels at $_labelsFileName, '
      'model at $_modelFileName',
    );

    final classifier = await Classifier.loadWith(
      labelsFileName: _labelsFileName,
      modelFileName: _modelFileName,
    );
    _classifier = classifier;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          const Spacer(
            flex: 2,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: _buildTitle(),
          ),
          const SizedBox(height: 20),
          Expanded(
            flex: 12,
            child: _buildPhotolView(),
          ),
          const SizedBox(height: 10),
          _buildResultView(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPickPhotoButton(
                title: 'Toma una photo',
                source: ImageSource.camera,
                icon: Icons.camera_alt
              ),
              _buildPickPhotoButton(
                title: 'Escoger desde galeria',
                source: ImageSource.gallery,
                icon: Icons.open_in_browser
              ),
            ],
          ),
          const Spacer(
            flex: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotolView() {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        HotDogPhotoView(file: _selectedImageFile),
        _buildAnalyzingText(),
      ],
    );
  }

  Widget _buildAnalyzingText() {
    if (!_isAnalyzing) {
      return const SizedBox.shrink();
    }
    return const Text('Analyzing...', style: kAnalyzingTextStyle);
  }

  Widget _buildTitle() {
    return const Text(
      'Hot Dog Recognizer',
      style: kTitleTextStyle,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPickPhotoButton({
    required ImageSource source,
    required String title,
    required IconData icon,
  }) {
    return TextButton(
      onPressed: () => _onPickPhoto(source),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Container(
          width: 150,
          height: 60,
          color: Colors.blue,
          child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white),
                  Text(title,style: TextStyle(color: Colors.white),)
                ],
              )),
        ),
      ),
    );
  }

  void _setAnalyzing(bool flag) {
    setState(() {
      _isAnalyzing = flag;
    });
  }

  void _onPickPhoto(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) {
      return;
    }

    final imageFile = File(pickedFile.path);
    setState(() {
      _selectedImageFile = imageFile;
    });

    _analyzeImage(imageFile);
  }

  void _analyzeImage(File image) {
    _setAnalyzing(true);

    final imageInput = img.decodeImage(image.readAsBytesSync())!;

    final resultCategory = _classifier!.predict(imageInput);

    final result = resultCategory.score >= 0.8
        ? _ResultStatus.found
        : _ResultStatus.notFound;
    final hotDogLabel = resultCategory.label;
    final accuracy = resultCategory.score;

    _setAnalyzing(false);

    setState(() {
      _resultStatus = result;
      _hotDogLabel = hotDogLabel;
      _accuracy = accuracy;
    });
  }

  Widget _buildResultView() {
    var title = '';

    if (_resultStatus == _ResultStatus.notFound) {
      title = 'Fail to recognise';
    } else if (_resultStatus == _ResultStatus.found) {
      title = _hotDogLabel;
    } else {
      title = '';
    }

    //
    var accuracyLabel = '';
    if (_resultStatus == _ResultStatus.found) {
      accuracyLabel = 'Accuracy: ${(_accuracy * 100).toStringAsFixed(2)}%';
    }

    return Column(
      children: [
        Text(title, style: kResultTextStyle),
        const SizedBox(height: 10),
        Text(accuracyLabel, style: kResultRatingTextStyle)
      ],
    );
  }
}
