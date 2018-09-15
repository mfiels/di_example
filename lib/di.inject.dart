import 'di.dart' as _i1;
import 'package:http/src/client.dart' as _i2;
import 'dart:collection' as _i3;
import 'dart:async' as _i4;

class AppInjector$Injector implements _i1.AppInjector {
  AppInjector$Injector._(this._module);

  final _i1.Module _module;

  _i2.Client _singletonClient;

  _i1.ITunesSearchService _singletonITunesSearchService;

  _i1.ITunesAlbumService _singletonITunesAlbumService;

  _i1.AlbumBloc _singletonAlbumBloc;

  _i3.UnmodifiableListView<_i1.Bloc> _singletonUnmodifiableListView;

  static _i4.Future<_i1.AppInjector> create(_i1.Module module) async {
    final injector = new AppInjector$Injector._(module);

    return injector;
  }

  _i3.UnmodifiableListView<_i1.Bloc> _createUnmodifiableListView() =>
      _singletonUnmodifiableListView ??= _module.blocs(_createAlbumBloc());
  _i1.AlbumBloc _createAlbumBloc() =>
      _singletonAlbumBloc ??= new _i1.AlbumBloc(_createITunesAlbumService());
  _i1.ITunesAlbumService _createITunesAlbumService() =>
      _singletonITunesAlbumService ??= new _i1.ITunesAlbumService(
          _createClient(), _createITunesSearchService());
  _i2.Client _createClient() => _singletonClient ??= _module.httpClient();
  _i1.ITunesSearchService _createITunesSearchService() =>
      _singletonITunesSearchService ??=
          new _i1.ITunesSearchService(_createClient());
  @override
  _i3.UnmodifiableListView<_i1.Bloc> blocs() => _createUnmodifiableListView();
}
