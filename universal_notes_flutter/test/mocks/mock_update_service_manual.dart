// test/mocks/mock_update_service_manual.dart

import 'package:mockito/mockito.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

// Crie uma classe de mock manual que implementa UpdateService
// e define explicitamente o método que estava faltando.
class MockUpdateService extends Mock implements UpdateService {
  @override
  Future<UpdateCheckResult> checkForUpdate() => (super.noSuchMethod(
        Invocation.method(#checkForUpdate, []),
        returnValue: Future.value(UpdateCheckResult(UpdateCheckStatus.noUpdate)),
        returnValueForMissingStub: Future.value(UpdateCheckResult(UpdateCheckStatus.noUpdate)),
      ) as Future<UpdateCheckResult>);
}
