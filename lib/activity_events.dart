import 'dart:async';

enum ActivityEvent { changed, sessionChanged }

// Shared by HTTP, sockets and push, without coupling them to the UI.
final activityEvents = StreamController<ActivityEvent>.broadcast(sync: true);
