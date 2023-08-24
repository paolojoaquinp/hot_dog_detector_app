import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hot_dog_detector/constants.dart';


class HotDogPhotoView extends StatelessWidget {
  const HotDogPhotoView({super.key,this.file});
  final File? file;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 250,
      color: Colors.blueGrey,
      child: (file == null)
        ? _buildEmptyView()
        : Image.file(file!, fit: BoxFit.cover)
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Text(
        'Selecciona una foto',
        textAlign: TextAlign.center,
        style: kAnalyzingTextStyle,
    ));
  }
}