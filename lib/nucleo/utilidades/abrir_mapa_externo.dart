import 'package:url_launcher/url_launcher.dart';

Future<void> abrirMapaExterno(double lat, double lng) async {
  final urlGoogleMaps = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
  final urlGeo = Uri.parse('geo:$lat,$lng?q=$lat,$lng');

  try {
    if (await canLaunchUrl(urlGoogleMaps)) {
      await launchUrl(urlGoogleMaps, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(urlGeo)) {
      await launchUrl(urlGeo, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(urlGoogleMaps, mode: LaunchMode.inAppWebView);
    }
  } catch (_) {
    await launchUrl(urlGoogleMaps, mode: LaunchMode.externalApplication);
  }
}
