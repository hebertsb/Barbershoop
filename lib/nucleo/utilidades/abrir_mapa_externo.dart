import 'package:url_launcher/url_launcher.dart';

Future<void> abrirMapaExterno(double lat, double lng) async {
  final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=\,');
  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
