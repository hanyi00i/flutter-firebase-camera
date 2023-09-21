import 'dart:async';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:advancti_firebase/constants/constants.dart';
import 'package:flutter/gestures.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  HomePageState({Key? key});
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
  GlobalKey<RefreshIndicatorState>();
  List<String> imageUrls = [];
  List<bool> selectedImages = [];

  @override
  void initState() {
    super.initState();
    getFirebaseImages();
  }

  Future<void> getFirebaseImages() async {
    try {
      final ListResult result = await FirebaseStorage.instance.ref().listAll();
      imageUrls.clear();
      selectedImages.clear();
      if (result.items.isEmpty) {
        setState(() {
          imageUrls = [];
          selectedImages = [];
        });
      } else {
        for (final Reference ref in result.items) {
          final url = await ref.getDownloadURL();
          setState(() {
            imageUrls.add(url);
            selectedImages.add(false);
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _uploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      try {
        final String timestamp =
        DateFormat('yyyyMMddHHmmss').format(DateTime.now());
        final Reference storageReference =
        _firebaseStorage.ref().child('$timestamp');
        final File pickedImageFile = File(pickedFile.path);
        final img.Image image =
        img.decodeImage(pickedImageFile.readAsBytesSync())!;
        final img.Image resizedImage = img.copyResize(image, width: 400);
        final File resizedFile = File(pickedFile.path);
        resizedFile.writeAsBytesSync(img.encodeJpg(resizedImage));
        await storageReference.putFile(resizedFile);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image uploaded to Firebase Storage'),
          ),
        );
        getFirebaseImages();
      } catch (e) {
        print(e);
      }
    }
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    bool areImagesSelected = selectedImages.any((selected) => selected);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: areImagesSelected
              ? Text("Are you sure you want to delete selected images?")
              : Text("Are you sure you want to delete all images?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                setState(() {
                  selectedImages =
                      List.generate(imageUrls.length, (_) => false);
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop();
                if (areImagesSelected) {
                  _deleteSelectedImages();
                } else {
                  _deleteAllImages();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAllImages() async {
    try {
      final ListResult result = await FirebaseStorage.instance.ref().listAll();
      for (final Reference ref in result.items) {
        await ref.delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All images deleted from Firebase Storage'),
        ),
      );
      getFirebaseImages();
    } catch (e) {
      print(e);
    }
  }

  Future<void> _deleteSelectedImages() async {
    try {
      List<int> indicesToDelete = [];
      for (int index = 0; index < selectedImages.length; index++) {
        if (selectedImages[index]) {
          indicesToDelete.add(index);
        }
      }
      for (int i = indicesToDelete.length - 1; i >= 0; i--) {
        final int indexToDelete = indicesToDelete[i];
        final String imageUrl = imageUrls[indexToDelete];
        final Reference refToDelete = FirebaseStorage.instance.refFromURL(imageUrl);
        await refToDelete.delete();
        imageUrls.removeAt(indexToDelete);
        selectedImages.removeAt(indexToDelete);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected images deleted from Firebase Storage'),
        ),
      );
      getFirebaseImages();
    } catch (e) {
      print('Error deleting selected images: $e');
    }
  }


  void _showImagePreviewDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            width: double.infinity,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.homeTitle,
          style: TextStyle(color: ColorConstants.primaryColor),
        ),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(
                Icons.delete,
                color: Colors.white,
              ),
              onPressed: () {
                _showDeleteConfirmationDialog(context);
              }),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: getFirebaseImages,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                      ),
                      itemCount: imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onLongPress: () {
                            _showImagePreviewDialog(imageUrls[index]);
                          },
                          child: Card(
                            elevation: 5,
                            margin: EdgeInsets.all(5),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: Image.network(imageUrls[index],
                                      fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Checkbox(
                                    value: selectedImages[index],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedImages[index] = value!;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _uploadImage,
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    primary: ColorConstants.primaryColor,
                  ),
                  child: Container(
                    width: 56.0,
                    height: 56.0,
                    child: Center(
                      child: Icon(
                        Icons.camera,
                        size: 36.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
