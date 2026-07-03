import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:misiembra_v0/services/geocoding_service.dart';

class ThrowingClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw http.ClientException('network issue');
  }
}

void main() {
  test('returns null when the geocoding request fails', () async {
    final result = await GeocodingService.reverseGeocode(
      4.6097,
      -74.0817,
      client: ThrowingClient(),
    );

    expect(result, isNull);
  });
}
