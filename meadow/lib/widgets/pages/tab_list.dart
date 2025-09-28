import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meadow/models/menu_item.dart';
import 'package:meadow/widgets/image_prompt_bar.dart';
import 'package:meadow/widgets/music_prompt_bar.dart';
import 'package:meadow/widgets/speech_prompt_bar.dart';
import 'package:meadow/widgets/shared/tasks_tab_icon.dart';
import 'package:meadow/widgets/tasks/tasks_list_widget.dart';
import 'package:meadow/widgets/video_prompt_bar.dart';
import 'package:meadow/widgets/video_transcript/video_transcript_list_tab.dart';

final List<MenuItem> tabList = [
  MenuItem(
    title: 'Image',
    icon: CupertinoIcons.photo,
    content: const ImagePromptBar(),
  ),
  MenuItem(
    title: 'Clips',
    icon: Icons.local_movies,
    content: const VideoPromptBar(),
  ),
  MenuItem(
    title: 'Music',
    icon: Icons.music_note,
    content: const MusicPromptBar(),
  ),
  MenuItem(
    title: 'Speech',
    icon: CupertinoIcons.speaker_2,
    content: const SpeechPromptBar(),
  ),
  MenuItem(
    title: 'Transcript',
    icon: CupertinoIcons.doc_text,
    content: const VideoTranscriptListTab(),
  ),
  MenuItem(
    title: 'Tasks',
    icon: CupertinoIcons.doc_checkmark,
    content: const TasksListTab(),
    customIconBuilder: () => const TasksTabIcon(),
  ),
];
