import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class Kirtan {
  final String smaagam;
  final String artist;
  final String url;

  Kirtan({this.smaagam, this.artist, this.url});

  factory Kirtan.fromJson(Map<String, dynamic> json) {
    return Kirtan(
      url: json['url'],
      smaagam: json['smaagam']['smaagam_name'].toString().replaceAll('Â', ''),
      artist: json['artist']['artist_name'].toString().replaceAll('Â', ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'smaagam': {
          'smaagam_name': smaagam,
        },
        'artist': {
          'artist_name': artist,
        },
      };
}

Future<List<Kirtan>> fetchKirtan(http.Client client, String url) async {
  final response = await client.get(url);

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseKirtan, response.body);
}

// A function that converts a response body into a List<Photo>.
List<Kirtan> parseKirtan(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Kirtan>((json) => Kirtan.fromJson(json)).toList();
}
