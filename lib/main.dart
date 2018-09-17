import 'dart:async';

import 'package:di_example/di.dart';
import 'package:flutter/material.dart';

Future main() async {
  var injector = await AppInjector.create(Module());
  var blocs = injector.blocs();
  runApp(ServiceProvider(blocs: blocs, child: App()));

  // Trigger the first fetch:
  (blocs.firstWhere((bloc) => bloc is AlbumBloc) as AlbumBloc).next.add(null);
}

class ServiceProvider extends InheritedWidget {
  final Map<Type, Bloc> _blocs;

  ServiceProvider({@required Iterable<Bloc> blocs, @required Widget child})
      : _blocs = blocs.fold(<Type, Bloc>{}, (Map<Type, Bloc> blocs, Bloc bloc) {
          blocs[bloc.runtimeType] = bloc;
          return blocs;
        }),
        super(child: child);

  static T blocOf<T extends Bloc>(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(ServiceProvider) as ServiceProvider)
          ._blocs[T];

  @visibleForTesting
  void addBlocForTest<T extends Bloc>(T bloc) => _blocs[T] = bloc;

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ServiceProvider.blocOf<AlbumBloc>(context).next.add(null);
        },
        child: Icon(Icons.music_note),
      ),
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
        Image.network(
          album.url,
          width: 100.0,
          height: 100.0,
        ),
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
