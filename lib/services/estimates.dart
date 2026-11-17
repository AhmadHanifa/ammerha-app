import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/config.dart';
import '../data/estimate.dart';

/// Asks the backend for the price range. The unit prices stay on the server:
/// the phone only ever receives the two ends of the range.
Future<Estimate> fetchEstimate(CalcInput input) async {
  if (!AppConfig.hasBackend) return demoEstimate(input);
  final json = await Supabase.instance.client
      .rpc('calc_estimate', params: input.rpcParams)
      .timeout(AppConfig.requestTimeout);
  return Estimate.fromJson(json as Map<String, dynamic>);
}
