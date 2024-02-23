import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String API_URL = 'http://192.168.88.60:3000';

class PlaylistItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final List<bool> likedItems;
  final Function(int) handleLikePress;
  final Function(String, int) playSound;
  final int? positionIndex;
  final Map<int, bool> isPlayingList;
  final Function pauseSound;
  final Function stopSound;
  final int position;
  final int duration;

  PlaylistItem({
    required this.item,
    required this.index,
    required this.likedItems,
    required this.handleLikePress,
    required this.playSound,
    this.positionIndex,
    required this.isPlayingList,
    required this.pauseSound,
    required this.stopSound,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => playSound('$API_URL/api/filename/${item['id']}', index),
      child: Container(
        margin: EdgeInsets.all(10),
        width: MediaQuery.of(context).size.width / 2 - 20,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              offset: const Offset(0, 2),
              blurRadius: 3.84,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                item['titre'],
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2264A0)),
              ),
            ),
            Image.network(
              '$API_URL/${item['nom_image']}',
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
            Container(
              height: 50,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20, color: Color(0xFF2264A0)),
                      SizedBox(width: 5),
                      Text(
                        DateFormat().format(DateTime.parse(item['date'])).toString(),
                        style: TextStyle(fontSize: 15, color: Color(0xFF2264A0)),
                      ),
                      Spacer(),
                      GestureDetector(
                        onTap: () => handleLikePress(index),
                        child: Icon(
                          likedItems[index] ? Icons.favorite : Icons.favorite_border,
                          size: 22,
                          color: Color(0xFF2264A0),
                        ),
                      ),
                    ],
                  ),
                  if (item['duration'] != null && item['duration'] > 0 && index == positionIndex)
                    LinearProgressIndicator(
                      value: position / duration,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2264A0)),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isPlayingList[index]!)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => pauseSound(),
                        icon: Icon(Icons.pause, size: 32, color: Color(0xFF2264A0)),
                      ),
                      IconButton(
                        onPressed: () => stopSound(),
                        icon: Icon(Icons.stop, size: 32, color: Color(0xFF2264A0)),
                      ),
                    ],
                  )
                else
                  IconButton(
                    onPressed: () => playSound('$API_URL/api/filename/${item['id']}', index),
                    icon: Icon(Icons.play_arrow, size: 32, color: Color(0xFF2264A0)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  List<Map<String, dynamic>> playlist = [];
  AudioPlayer audioPlayer = AudioPlayer();
  bool isPlaying = false;
  int position = 0;
  int duration = 0;
  int? positionIndex;
  Map<int, bool> isPlayingList = {};
  List<bool> likedItems = [];

  @override
  void initState() {
    super.initState();
    fetchPlaylists();
  }

  void fetchPlaylists() async {
    try {
      final response = await http.get(Uri.parse('$API_URL/api/allplaylist'));
      final data = json.decode(response.body);

      if (data['success']) {
        setState(() {
          playlist = List<Map<String, dynamic>>.from(data['playlists']);
          likedItems = List.generate(playlist.length, (index) => false);
        });
      } else {
        print('Erreur lors de la récupération des playlists: ${data['message']}');
      }
    } catch (error) {
      print('Erreur lors de la récupération des playlists: $error');
    }
  }

  void playSound(String filename, int index) async {
    try {
      if (audioPlayer.state == AudioPlayerState.PLAYING) {
        await audioPlayer.stop();
      }
      await audioPlayer.play(filename, isLocal: false);
      setState(() {
        isPlaying = true;
        isPlayingList[index] = true;
        positionIndex = index;
      });
      audioPlayer.onAudioPositionChanged.listen((Duration p) {
        if (mounted) {
          setState(() {
            position = p.inMilliseconds;
          });
        }
      });

      audioPlayer.onDurationChanged.listen((Duration d) {
        if (mounted) {
          setState(() {
            duration = d.inMilliseconds;
          });
        }
      });
    } catch (error) {
      print('Erreur lors de la lecture du son: $error');
    }
  }

  void pauseSound() async {
    try {
      await audioPlayer.pause();
      setState(() {
        isPlaying = false;
      });
    } catch (error) {
      print('Erreur lors de la pause du son: $error');
    }
  }

  void stopSound() async {
    try {
      await audioPlayer.stop();
      setState(() {
        isPlaying = false;
        positionIndex = null;
      });
    } catch (error) {
      print('Erreur lors de l\'arrêt du son: $error');
    }
  }

  void handleLikePress(int index) {
    setState(() {
      likedItems[index] = !likedItems[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Playlist'),
          actions: [
            IconButton(
              icon: Icon(Icons.add_circle),
              onPressed: () {
                // Implement the logic for handling the modal here
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: playlist
                  .asMap()
                  .entries
                  .map(
                    (entry) => PlaylistItem(
                      item: entry.value,
                      index: entry.key,
                      likedItems: likedItems,
                      handleLikePress: handleLikePress,
                      playSound: playSound,
                      positionIndex: positionIndex,
                      isPlayingList: isPlayingList,
                      pauseSound: pauseSound,
                      stopSound: stopSound,
                      position: position,
                      duration: duration,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // Implement the logic for handling the modal here
          },
          child: Icon(Icons.add),
        ),
      ),
    );
  }
}

void main() {
  runApp(App());
}
