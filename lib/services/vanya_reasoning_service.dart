import '../models/intervention_context.dart';
import '../models/vanya_decision.dart';

/// The seam between "AI decides" and everything else. The intervention UI
/// and, eventually, Android enforcement should only ever talk to this
/// interface — never to a specific model provider directly — so that
/// swapping `MockVanyaReasoningService` for a real `ActualVanyaReasoningService`
/// later is a one-line change, not a rewrite.
abstract class VanyaReasoningService {
  Future<VanyaDecision> evaluate(InterventionContext context);
}
