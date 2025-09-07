import 'package:animetrace/utils/log.dart';
import 'package:flutter/material.dart';

class RouteLogObserver extends NavigatorObserver {
  RouteLogObserver();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name == null) return;
    AppLog.info(_genRouteInfo('push', route, previousRoute));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (route.settings.name == null) return;
    AppLog.info(_genRouteInfo('pop', route, previousRoute));
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    if (route.settings.name == null) return;
    AppLog.info(_genRouteInfo('remove', route, previousRoute));
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name == null) return;
    AppLog.info(_genRouteInfo('replace', newRoute, oldRoute));
  }

  String _genRouteInfo(
      String action, Route<dynamic>? route, Route<dynamic>? oldRoute) {
    String msg = action;
    if (route != null) msg += ' "${route.settings.name ?? '<unknown>'}"';
    if (oldRoute != null) {
      msg += ' from "${oldRoute.settings.name ?? '<unknown>'}"';
    }
    if (route?.settings.arguments != null) {
      msg += '\nArguments: ${route?.settings.arguments?.toString()}';
    }
    return msg;
  }
}
