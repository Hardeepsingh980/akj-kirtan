import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:akj/models.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';
import 'package:http/http.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int curIndex;

  StreamSubscription durationSubscription;
  StreamSubscription positionSubscription;
  StreamSubscription audioPlayerSubscription;

  List<Kirtan> kirtan;
  List<Kirtan> searchkirtan;

  List<Kirtan> favKirtan = [];
  List<String> favUrl = [];
  SharedPreferences prefs;

  TextEditingController searchText = TextEditingController();

  TabController _tabController;

  Future loadingKirtan;
  Future searchDocs;
  bool isSearching = false;

  String searchBy = 'Smaagam';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, initialIndex: 0, length: 4);

    loadingKirtan =
        fetchKirtan(http.Client(), 'https://akjm.herokuapp.com/kirtan/latest/');

    initPlayer();
    initSharedPreferences();
  }

  initSharedPreferences() async {
    prefs = await SharedPreferences.getInstance();
    List l = prefs.getStringList('favourites');
    List data = [];
    l.forEach((f) => data.add(jsonDecode(f)));
    favKirtan = data.map<Kirtan>((json) => Kirtan.fromJson(json)).toList();
    setState(() {
      favUrl = [];
      favKirtan.forEach((f) => favUrl.add(f.url));
    });
  }

  void initPlayer() {
    advancedPlayer = AudioPlayer();
    audioCache = AudioCache(fixedPlayer: advancedPlayer);

    audioPlayerSubscription =
        advancedPlayer.onPlayerCompletion.listen((d) => setState(() {
              MediaNotification.hideNotification();
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

    MediaNotification.setListener('pause', () {
      setState(() {
        advancedPlayer.pause();
        playerState = AudioPlayerState.PAUSED;
      });
    });

    MediaNotification.setListener('play', () {
      setState(() {
        advancedPlayer.resume();
        playerState = AudioPlayerState.PLAYING;
      });
    });

    MediaNotification.setListener('next', () {
      setState(() {
        curPlaying = kirtan[curIndex + 1];
        curIndex = curIndex + 1;
        playerState = AudioPlayerState.PLAYING;
        advancedPlayer.play(kirtan[curIndex + 1].url);
        MediaNotification.showNotification(
          title: curPlaying.artist,
          author: curPlaying.smaagam,
        );
      });
    });

    MediaNotification.setListener('prev', () {
      setState(() {
        curPlaying = kirtan[curIndex - 1];
        curIndex = curIndex - 1;
        playerState = AudioPlayerState.PLAYING;
        advancedPlayer.play(kirtan[curIndex + 1].url);
        MediaNotification.showNotification(
          title: curPlaying.artist,
          author: curPlaying.smaagam,
        );
      });
    });
  }

  void submit(String searchValue) async {
    var url;
    if (searchBy == 'Smaagam') {
      url = 'https://akjm.herokuapp.com/kirtan/smaagam/?search=$searchValue';
    } else {
      url = 'https://akjm.herokuapp.com/kirtan/artist/?search=$searchValue';
    }

    print(url);

    var response = get(url);

    print(response);

    setState(() {
      isSearching = false;
      searchDocs = response;
    });
  }

  ListView buildSearchResults(docs) {
    List<Widget> userSearchItems = [];

    var parsed = jsonDecode(docs);

    parsed = parsed.reversed.toList();

    var searchResults =
        parsed.map<Kirtan>((json) => Kirtan.fromJson(json)).toList();

    searchResults.forEach((Kirtan k) async {
      Widget searchItem = Padding(
        padding: const EdgeInsets.all(5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.black,
            child: ListTile(
              onTap: () {
                setState(() {
                  curPlaying = k;
                  playerState = AudioPlayerState.PLAYING;
                  advancedPlayer.play(k.url);
                  MediaNotification.showNotification(
                    title: curPlaying.artist,
                    author: curPlaying.smaagam,
                  );
                });
              },
              trailing: favUrl.contains(k.url)
                  ? IconButton(
                      icon: Icon(Icons.favorite),
                      onPressed: () {
                        favKirtan.removeAt(favUrl.indexOf(k.url));

                        List<String> list = [];
                        favKirtan.forEach((f) => list.add(json.encode(f)));
                        save(list);
                      },
                    )
                  : IconButton(
                      icon: Icon(Icons.favorite_border),
                      onPressed: () {
                        favKirtan.add(k);

                        List<String> list = [];
                        favKirtan.forEach((f) => list.add(json.encode(f)));
                        save(list);
                      },
                    ),
              title: Text(k.artist),
              subtitle: Text(k.smaagam),
            ),
          ),
        ),
      );

      userSearchItems.add(searchItem);
    });

    return ListView(
      children: userSearchItems,
    );
  }

  save(List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('favourites', value);
    setState(() {
      initSharedPreferences();
    });
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
            Tab(icon: Icon(Icons.new_releases)),
            Tab(icon: Icon(Icons.search)),
            Tab(
              icon: Icon(Icons.favorite),
            ),
            Tab(icon: Icon(Icons.file_download)),
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
                                        curIndex = i;
                                        playerState = AudioPlayerState.PLAYING;
                                        advancedPlayer.play(kirtan[i].url);
                                        MediaNotification.showNotification(
                                          title: curPlaying.artist,
                                          author: curPlaying.smaagam,
                                        );
                                      });
                                    },
                                    trailing: favUrl.contains(kirtan[i].url)
                                        ? IconButton(
                                            icon: Icon(Icons.favorite),
                                            onPressed: () {
                                              favKirtan.removeAt(favUrl
                                                  .indexOf(kirtan[i].url));

                                              List<String> list = [];
                                              favKirtan.forEach((f) =>
                                                  list.add(json.encode(f)));
                                              save(list);
                                            },
                                          )
                                        : IconButton(
                                            icon: Icon(Icons.favorite_border),
                                            onPressed: () {
                                              favKirtan.add(kirtan[i]);

                                              List<String> list = [];
                                              favKirtan.forEach((f) =>
                                                  list.add(json.encode(f)));
                                              save(list);
                                            },
                                          ),
                                    title: Text(kirtan[i].artist),
                                    subtitle: Text(kirtan[i].smaagam),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(child: CircularProgressIndicator());
                  },
                ),
                Scaffold(
                  appBar: AppBar(
                    title: Form(
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: 'Search for $searchBy ...'),
                        onFieldSubmitted: submit,
                      ),
                    ),
                    actions: <Widget>[
                      DropdownButton<String>(
                        value: searchBy,
                        items: <String>['Smaagam', 'Kirtaaniya']
                            .map((String value) {
                          return new DropdownMenuItem<String>(
                            value: value,
                            child: new Text(value),
                          );
                        }).toList(),
                        onChanged: (_) {
                          setState(() {
                            searchBy = _;
                          });
                        },
                      )
                    ],
                  ),
                  body: searchDocs == null
                      ? Center(
                          child: Text('Search for a relevent keyword ...'),
                        )
                      : FutureBuilder(
                          future: searchDocs,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.done) {
                              return buildSearchResults(snapshot.data.body);
                            } else {
                              return Container(
                                  alignment: FractionalOffset.center,
                                  child: CircularProgressIndicator());
                            }
                          }),
                ),
                favKirtan.length != 0
                    ? ListView.builder(
                        itemCount: favKirtan.length,
                        itemBuilder: (_, i) => Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              color: Colors.black,
                              child: ListTile(
                                onTap: () {
                                  setState(() {
                                    curPlaying = favKirtan[i];
                                    curIndex = i;
                                    playerState = AudioPlayerState.PLAYING;
                                    advancedPlayer.play(favKirtan[i].url);
                                    MediaNotification.showNotification(
                                      title: curPlaying.artist,
                                      author: curPlaying.smaagam,
                                    );
                                  });
                                },
                                trailing: favKirtan.contains(favKirtan[i])
                                    ? IconButton(
                                        icon: Icon(Icons.favorite),
                                        onPressed: () {
                                          favKirtan.removeAt(
                                              favKirtan.indexOf(favKirtan[i]));

                                          List<String> list = [];
                                          favKirtan.forEach(
                                              (f) => list.add(json.encode(f)));
                                          save(list);
                                        },
                                      )
                                    : IconButton(
                                        icon: Icon(Icons.favorite_border),
                                        onPressed: () {
                                          favKirtan.add(favKirtan[i]);

                                          List<String> list = [];
                                          favKirtan.forEach(
                                              (f) => list.add(json.encode(f)));
                                          save(list);
                                        },
                                      ),
                                title: Text(favKirtan[i].artist),
                                subtitle: Text(favKirtan[i].smaagam),
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text('Nothing In Favorites'),
                      ),
                Center(child: Text('Coming Soon ....')),
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
                          child: Text(curPlaying.artist),
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
                        onPressed: curIndex != null
                            ? curIndex - 1 >= 0
                                ? () {
                                    setState(() {
                                      curPlaying = kirtan[curIndex - 1];
                                      curIndex = curIndex - 1;
                                      playerState = AudioPlayerState.PLAYING;
                                      advancedPlayer
                                          .play(kirtan[curIndex + 1].url);
                                      MediaNotification.showNotification(
                                        title: curPlaying.artist,
                                        author: curPlaying.smaagam,
                                      );
                                    });
                                  }
                                : null
                            : null,
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
                                      MediaNotification.showNotification(
                                        title: curPlaying.artist,
                                        author: curPlaying.smaagam,
                                      );
                                    });
                                  }
                                : () {
                                    setState(() {
                                      advancedPlayer.pause();
                                      playerState = AudioPlayerState.PAUSED;
                                      MediaNotification.showNotification(
                                          title: curPlaying.artist,
                                          author: curPlaying.smaagam,
                                          isPlaying: false);
                                    });
                                  },
                        iconSize: 40,
                      ),
                      IconButton(
                        icon: Icon(Icons.skip_next),
                        onPressed: curIndex != null
                            ? curIndex + 1 < kirtan.length
                                ? () {
                                    setState(() {
                                      curPlaying = kirtan[curIndex + 1];
                                      curIndex = curIndex + 1;
                                      playerState = AudioPlayerState.PLAYING;
                                      advancedPlayer
                                          .play(kirtan[curIndex + 1].url);
                                      MediaNotification.showNotification(
                                        title: curPlaying.artist,
                                        author: curPlaying.smaagam,
                                      );
                                    });
                                  }
                                : null
                            : null,
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
