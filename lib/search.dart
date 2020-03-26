import 'package:akj/models.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Widget searchList(kirtan, curPlaying, advancedPlayer, playerState, setState) {
  return SingleChildScrollView(
    child: Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(10.0),
                    ),
                  ),
                  hintText: 'Search ... '),
            ),
            SizedBox(
              width: 20,
            ),
            IconButton(icon: Icon(Icons.search), onPressed: null)
          ],
        ),
      ],
    ),
  );
}
