import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class Smaagam {
  final String name;

  Smaagam({this.name});

  factory Smaagam.fromJson(Map<String, dynamic> json) {
    return Smaagam(
      name: json['smaagam_name'].toString().replaceAll('Â', ''),
    );
  }

}

class Artist {
  final String name;

  Artist({this.name});

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      name: json['artist_name'].toString().replaceAll('Â', ''),
    );
  }

}

class Kirtan {
  final Smaagam smaagam;
  final Artist artist;
  final String url;

  Kirtan({this.smaagam, this.artist, this.url});

  factory Kirtan.fromJson(Map<String, dynamic> json) {
    return Kirtan(
      url: json['url'],
      smaagam:  Smaagam.fromJson(json['smaagam']),
      artist: Artist.fromJson(json['artist'])
    );
  }

}




Future<List<Kirtan>> fetchKirtan(http.Client client, String url) async {
  final response = await client
      .get(url);

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseKirtan, response.body);
}

// A function that converts a response body into a List<Photo>.
List<Kirtan> parseKirtan(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed
      .map<Kirtan>((json) => Kirtan.fromJson(json))
      .toList();
}