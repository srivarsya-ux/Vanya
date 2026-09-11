import 'app_access_controller.dart';
import 'intervention_flow_service.dart';
import 'intervention_history_service.dart';
import 'mock_vanya_reasoning_service.dart';
import 'protected_app_service.dart';
import 'task_service.dart';
import 'temporary_access_service.dart';

/// Every service the intervention system needs, loaded once and handed
/// around — the same bundle [HomeScreen] and the Android-launched
/// intervention entry point both build themselves from, so there's one
/// definition of "what a fully-initialized Vanya core looks like" rather
/// than two copies that could drift apart.
class CoreServices {
  const CoreServices({
    required this.taskService,
    required this.protectedAppService,
    required this.temporaryAccessService,
    required this.historyService,
    required this.reasoningService,
    required this.flow,
    required this.access,
  });

  final TaskService taskService;
  final ProtectedAppService protectedAppService;
  final TemporaryAccessService temporaryAccessService;
  final InterventionHistoryService historyService;
  final MockVanyaReasoningService reasoningService;
  final InterventionFlowService flow;
  final AppAccessController access;

  static Future<CoreServices> load() async {
    final taskService = await TaskService.load();
    final protectedAppService = await ProtectedAppService.load();
    final temporaryAccessService = await TemporaryAccessService.load();
    final historyService = await InterventionHistoryService.load();
    final reasoningService = MockVanyaReasoningService();
    final flow = InterventionFlowService(
      taskService: taskService,
      temporaryAccessService: temporaryAccessService,
      historyService: historyService,
      reasoningService: reasoningService,
    );
    return CoreServices(
      taskService: taskService,
      protectedAppService: protectedAppService,
      temporaryAccessService: temporaryAccessService,
      historyService: historyService,
      reasoningService: reasoningService,
      flow: flow,
      access: AppAccessController(
        protectedAppService: protectedAppService,
        temporaryAccessService: temporaryAccessService,
        flow: flow,
      ),
    );
  }
}
