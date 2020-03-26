import 'package:akj/models.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


Widget kirtanList(kirtan, curPlaying,advancedPlayer, playerState, setState) {
  return FutureBuilder<List<Kirtan>>(
    future: fetchKirtan(http.Client(),''),
    builder: (_, snapshot) {
  if (snapshot.hasData) {
    kirtan = snapshot.data;
  }
  return snapshot.hasData
      ? ListView.builder(
          itemCount: kirtan.length,
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.all(5.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: Colors.black,
                child: ListTile(
                  onTap: () {
                    setState(() {
                      curPlaying = kirtan[i];

                    playerState = AudioPlayerState.PLAYING;
                    advancedPlayer.play(kirtan[i].url);
                    });           
                  },
                  trailing: Icon(Icons.favorite_border),
                  title: Text(kirtan[i].artist.name),
                  subtitle: Text(kirtan[i].smaagam.name),
                ),
              ),
            ),
          ),
        )
      : Center(child: CircularProgressIndicator());
    },
  );
}

