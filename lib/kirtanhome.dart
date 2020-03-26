import 'dart:async';
import 'package:akj/kirtanlist.dart';
import 'package:akj/search.dart';
import 'package:http/http.dart' as http;
import 'package:akj/models.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';

class KirtanHome extends StatefulWidget {
  @override
  _KirtanHomeState createState() => _KirtanHomeState();
}

class _KirtanHomeState extends State<KirtanHome>
    with
        SingleTickerProviderStateMixin,
        AutomaticKeepAliveClientMixin<KirtanHome> {
  Duration duration;
  Duration position;
  AudioPlayer advancedPlayer;
  AudioCache audioCache;

  Kirtan curPlaying;
  AudioPlayerState playerState = AudioPlayerState.PAUSED;

  StreamSubscription durationSubscription;
  StreamSubscription positionSubscription;
  StreamSubscription audioPlayerSubscription;

  List<Kirtan> kirtan;
  List<Kirtan> searchkirtan;

  bool isSearch = false;
  TextEditingController searchText = TextEditingController();

  TabController _tabController;

  Future loadingKirtan;
  Future searchLoadingKirtan;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, initialIndex: 1, length: 4);

    loadingKirtan =
        fetchKirtan(http.Client(), 'https://akjm.herokuapp.com/api/kirtan/');

    searchLoadingKirtan = fetchKirtan(http.Client(),
        'https://akjm.herokuapp.com/api/kirtan/?search=${searchText.text}');

    initPlayer();
  }

  void initPlayer() {
    advancedPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: advancedPlayer);

    audioPlayerSubscription =
        advancedPlayer.onPlayerCompletion.listen((d) => setState(() {
              playerState = AudioPlayerState.PAUSED;
              duration = Duration(seconds: 0);
              position = Duration(seconds: 0);
              curPlaying = null;
            }));

    durationSubscription =
        advancedPlayer.onDurationChanged.listen((d) => setState(() {
              duration = d;
            }));

    positionSubscription =
        advancedPlayer.onAudioPositionChanged.listen((p) => setState(() {
              position = p;
            }));
  }

  void seekToSecond(int second, advancedPlayer) {
    Duration newDuration = Duration(seconds: second);

    advancedPlayer.seek(newDuration);
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return "$n";
      return "0$n";
    }

    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('AKJ Kirtan'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: <Widget>[
            Tab(icon: Text('LATEST')),
            Tab(icon: Text('SEARCH')),
            Tab(
              icon: Text('FAVOURITE'),
            ),
            Tab(
              icon: Text('HISTORY'),
            )
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                FutureBuilder<List<Kirtan>>(
                  future: loadingKirtan,
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
                ),
                Container(
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            onSubmitted: (v) {
                              print('searching');
                              setState(() {
                                isSearch = true;
                              });
                            },
                            controller: searchText,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20.0),
                                  ),
                                ),
                                hintText: 'Search ... '),
                          ),
                        ),
                        isSearch
                            ? FutureBuilder<List<Kirtan>>(
                                future: searchLoadingKirtan,
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    searchkirtan = snapshot.data;
                                  }
                                  return snapshot.hasData
                                      ? ListView.builder(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount: searchkirtan.length,
                                          itemBuilder: (_, i) => Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: Container(
                                                color: Colors.black,
                                                child: ListTile(
                                                  onTap: () {
                                                    setState(() {
                                                      curPlaying =
                                                          searchkirtan[i];

                                                      playerState =
                                                          AudioPlayerState
                                                              .PLAYING;
                                                      advancedPlayer.play(
                                                          searchkirtan[i].url);
                                                    });
                                                  },
                                                  trailing: Icon(
                                                      Icons.favorite_border),
                                                  title: Text(searchkirtan[i]
                                                      .artist
                                                      .name),
                                                  subtitle: Text(searchkirtan[i]
                                                      .smaagam
                                                      .name),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: CircularProgressIndicator());
                                })
                            : Center(child: Text('Search Kirtan')),
                      ],
                    ),
                  ),
                ),
                Text('Favourite'),
                Text('History')
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: Container(
              color: Theme.of(context).primaryColor,
              child: Column(
                children: <Widget>[
                  curPlaying != null
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(curPlaying.artist.name),
                        )
                      : Container(),
                  Row(
                    children: <Widget>[
                      Expanded(
                          child: Slider(
                              activeColor: Colors.white,
                              value: position != null
                                  ? position.inSeconds.toDouble()
                                  : 0,
                              min: 0.0,
                              max: duration != null
                                  ? duration.inSeconds.toDouble()
                                  : 0,
                              onChanged: (double value) {
                                setState(() {
                                  seekToSecond(value.toInt(), advancedPlayer);
                                  value = value;
                                });
                              })),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(position != null
                          ? _printDuration(position).toString()
                          : '00:00'),
                      IconButton(
                        icon: Icon(Icons.skip_previous),
                        onPressed: null,
                        iconSize: 40,
                      ),
                      IconButton(
                        icon: playerState == AudioPlayerState.PAUSED
                            ? Icon(Icons.play_arrow)
                            : Icon(Icons.pause),
                        onPressed:
                            // () => widget.advancedPlayer.stop(),
                            playerState == AudioPlayerState.PAUSED
                                ? () {
                                    setState(() {
                                      advancedPlayer.resume();
                                      playerState = AudioPlayerState.PLAYING;
                                    });
                                  }
                                : () {
                                    setState(() {
                                      advancedPlayer.pause();
                                      playerState = AudioPlayerState.PAUSED;
                                    });
                                  },
                        iconSize: 40,
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next),
                        onPressed: null,
                        iconSize: 40,
                      ),
                      Text(duration != null
                          ? _printDuration(duration).toString()
                          : '00:00')
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
