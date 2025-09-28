import 'package:get/get.dart';
import 'package:meadow/models/asset.dart';
import 'package:meadow/models/document_tab.dart';
import 'package:meadow/models/video_transcript.dart';
import 'package:meadow/widgets/video_transcript/video_transcript_viewer.dart';

class DocumentsTabsController extends GetxController {
  var documents = <DocumentTab>[].obs;
  var activeTabIndex = 0.obs;

  void openTab(Asset asset) {
    // Check if tab already exists
    final existingIndex = documents.indexWhere((tab) => tab.id == asset.id);

    if (existingIndex >= 0) {
      // Tab already exists, just switch to it
      activeTabIndex.value =
          existingIndex + 1; // +1 because assets tab is at index 0
    } else {
      // Create new tab
      final newTab = DocumentTab.fromAsset(asset);
      documents.add(newTab);
      activeTabIndex.value = documents.length; // Switch to the new tab
    }
    update();
  }

  void openTabAndSwitch(DocumentTab tab) {
    documents.add(tab);
    activeTabIndex.value = documents.length; // Switch to the new tab
    update();
  }

  void openVideoTranscriptTab(VideoTranscript transcript) {
    // Check if tab already exists
    final existingIndex = documents.indexWhere(
      (tab) => tab.id == transcript.id,
    );

    if (existingIndex >= 0) {
      // Tab already exists, just switch to it
      activeTabIndex.value =
          existingIndex + 1; // +1 because assets tab is at index 0
    } else {
      // Create new tab for video transcript
      final newTab = DocumentTab(
        id: transcript.id,
        title: transcript.title,
        content: VideoTranscriptViewer(transcript: transcript),
      );
      documents.add(newTab);
      activeTabIndex.value = documents.length; // Switch to the new tab
    }
    update();
  }

  Future<void> closeTab(DocumentTab tab) async {
    documents.remove(tab);

    // Adjust active tab index if necessary
    if (activeTabIndex.value > documents.length) {
      activeTabIndex.value = documents.length;
    }

    update();
  }

  void closeTabAt(int index) {
    if (index >= 0 && index < documents.length) {
      documents.removeAt(index);

      // Adjust active tab index if necessary
      if (activeTabIndex.value > documents.length) {
        activeTabIndex.value = documents.length;
      }

      update();
    }
  }

  void switchToTab(int index) {
    if (index >= 0 && index <= documents.length) {
      activeTabIndex.value = index;
      update();
    }
  }
}
