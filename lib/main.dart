import 'dart:async';

import 'package:di_example/di.dart';
import 'package:flutter/material.dart';

Future main() async {
  var injector = await AppInjector.create(Module());
  var blocs = injector.blocs();
  runApp(ServiceProvider(blocs: blocs, child: App()));
  toggle(blocs.firstWhere((b) => b is AlbumBloc));
}

Future toggle(AlbumBloc bloc) async {
  var index = 0;
  return Future.doWhile(() async {
    const artists = [
      'brand new',
      'modest mouse',
      'queens of the stone age',
      'arctic monkeys',
    ];
    bloc.search.add(artists[index++ % artists.length]);
    await Future.delayed(Duration(seconds: 5));
    return true;
  });
}

class ServiceProvider extends InheritedWidget {
  final Map<Type, Bloc> _blocs;

  ServiceProvider({@required Iterable<Bloc> blocs, @required Widget child})
      : _blocs = blocs.fold(<Type, Bloc>{}, (Map<Type, Bloc> blocs, Bloc bloc) {
          blocs[bloc.runtimeType] = bloc;
          return blocs;
        }),
        super(child: child);

  static T blocOf<T>(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(ServiceProvider) as ServiceProvider)
          ._blocs[T] as T;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Albums',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Albums'),
      ),
      body: Albums(),
    );
  }
}

class Albums extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Album>>(
      stream: ServiceProvider.blocOf<AlbumBloc>(context).albums,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: Text(
              'Loading...',
              softWrap: true,
            ),
          );
        }
        return ListView(
          children: snapshot.data
              .map((album) => AlbumRow(
                    album: album,
                  ))
              .toList(),
        );
      },
    );
  }
}

class AlbumRow extends StatelessWidget {
  final Album album;

  AlbumRow({@required this.album});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.network(album.url),
        Flexible(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              album.name,
              style: TextStyle(
                fontSize: 22.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
