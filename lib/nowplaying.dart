import 'package:akj/kirtanlist.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class NowPlaying extends StatefulWidget {
  Duration position;
  Duration duration;
  AudioPlayer advancedPlayer;
  String curPlaying;
  AudioPlayerState playerState;

  NowPlaying(
      {Key key,
      this.position,
      this.duration,
      this.advancedPlayer,
      this.curPlaying,
      this.playerState})
      : super(key: key);

  @override
  _NowPlayingState createState() => _NowPlayingState();
}

class _NowPlayingState extends State<NowPlaying> {
  void seekToSecond(int second, advancedPlayer) {
    Duration newDuration = Duration(seconds: second);

    advancedPlayer.seek(newDuration);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      child: Container(
        color: Theme.of(context).primaryColor,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Slider(
                        activeColor: Colors.white,
                        value: widget.position.inSeconds.toDouble(),
                        min: 0.0,
                        max: widget.duration.inSeconds.toDouble(),
                        onChanged: (double value) {
                          setState(() {
                            seekToSecond(value.toInt(), widget.advancedPlayer);
                            value = value;
                          });
                        })),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('00:00'),
                IconButton(
                  icon: Icon(Icons.skip_previous),
                  onPressed: null,
                  iconSize: 40,
                ),
                IconButton(
                  icon: widget.playerState == AudioPlayerState.PAUSED
                      ? Icon(Icons.pause)
                      : Icon(Icons.play_arrow),
                  onPressed:
                      // () => widget.advancedPlayer.stop(),
                      widget.playerState == AudioPlayerState.PAUSED
                          ? () {
                              setState(() {
                                widget.advancedPlayer.pause();
                                widget.playerState = AudioPlayerState.PAUSED;
                              });
                            }
                          : () {
                              if (widget.curPlaying != null) {
                                widget.advancedPlayer.play(widget.curPlaying);
                              }
                            },
                  iconSize: 40,
                ),
                IconButton(
                  icon: Icon(Icons.skip_next),
                  onPressed: null,
                  iconSize: 40,
                ),
                Text('00:00')
              ],
            ),
          ],
        ),
      ),
    );
  }
}
