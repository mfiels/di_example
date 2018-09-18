import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inject/inject.dart';
import 'package:rxdart/rxdart.dart';

import 'di.inject.dart' as generated;

abstract class Bloc {}

@provide
@singleton
class AlbumBloc implements Bloc {
  static const _artists = [
    'brand new',
    'modest mouse',
    'queens of the stone age',
    'arctic monkeys',
    'tame impala',
    'taking back sunday',
    'lcd soundsystem',
  ];

  final ITunesAlbumService _service;

  final _albums = BehaviorSubject<List<Album>>();
  final _next = StreamController<void>();
  var _index = 0;

  AlbumBloc(this._service) {
    _next.stream.listen(_handleNext);
  }

  Future _handleNext(_) async => _albums.add(
      await _service.fetchAlbumNames(_artists[_index++ % _artists.length]));

  Stream<List<Album>> get albums => _albums.stream;
  Sink<void> get next => _next.sink;
}

class Album {
  final String name;
  final String url;
  final DateTime release;
  Album(this.name, this.url, this.release);
}

@provide
@singleton
class ITunesAlbumService {
  final http.Client _client;
  final ITunesSearchService _searchService;

  ITunesAlbumService(this._client, this._searchService);

  Future<List<Album>> fetchAlbumNames(String query) async {
    var artistId = await _searchService.guessArtistId(query);
    var response = await _client
        .get('https://itunes.apple.com/lookup?id=$artistId&entity=album');
    if (response.statusCode != 200) throw 'Invalid response.';
    var payload = json.decode(response.body);

    var results = payload['results'];
    return results
        .where((result) => result['collectionName'] != null)
        .where((result) => result['artworkUrl100'] != null)
        .where((result) => result['releaseDate'] != null)
        .map<Album>((result) => Album(
              result['collectionName'],
              result['artworkUrl100'],
              DateTime.parse(result['releaseDate']),
            ))
        .toList()
          ..sort((Album a, Album b) => a.release.compareTo(b.release));
  }
}

@provide
@singleton
class ITunesSearchService {
  final http.Client _client;

  ITunesSearchService(this._client);

  Future<int> guessArtistId(String query) async {
    var response = await _client.get(
        'https://itunes.apple.com/search?term=${query.replaceAll(' ', '+')}');
    if (response.statusCode != 200) throw 'Invalid response.';
    var payload = json.decode(response.body);

    var results = payload['results'];
    var artistIdCounts = results
        .map((result) => result['artistId'])
        .where((artistId) => artistId != null)
        .cast<int>()
        .fold<Map<int, int>>(<int, int>{}, (Map<int, int> map, int artistId) {
      map.putIfAbsent(artistId, () => 0);
      map[artistId]++;
      return map;
    });

    var mostCommonArtistId = artistIdCounts.keys.fold(null, (current, next) {
      if (current == null) return next;
      if (artistIdCounts[current] < artistIdCounts[next]) return next;
      return current;
    });

    if (mostCommonArtistId == null) throw 'Failed to guess.';

    return mostCommonArtistId;
  }
}

@module
class Module {
  @provide
  @singleton
  http.Client httpClient() => http.Client();

  @provide
  @singleton
  UnmodifiableListView blocs(AlbumBloc albumBloc) =>
      UnmodifiableListView<Bloc>([albumBloc]);
}

@Injector(const [Module])
abstract class AppInjector {
  static final create = generated.AppInjector$Injector.create;

  @provide
  UnmodifiableListView blocs();
}
