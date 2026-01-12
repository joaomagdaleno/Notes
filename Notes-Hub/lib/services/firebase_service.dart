import 'dart:async';

import 'package:notes_hub/models/document_model.dart';

/// Um serviço simulado que imita a funcionalidade do Firestore para
/// colaboração em tempo real.
///
/// Em uma implementação real, este serviço se conectaria ao Firebase para
/// sincronizar os dados da nota e o status de presença dos colaboradores.
class FirebaseService {
  // Simula um "documento" do Firestore para a nota.
  final Map<String, dynamic> _documentData = {
    'content': DocumentModel.empty().toJson(),
  };

  // Simula uma coleção de "presença" para os cursores dos usuários.
  final Map<String, Map<String, dynamic>> _presenceData = {};

  // Controladores de stream para emitir atualizações simuladas.
  final _documentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _presenceController =
      StreamController<Map<String, Map<String, dynamic>>>.broadcast();

  /// O stream de dados do documento da nota.
  ///
  /// Emite o estado atual do documento sempre que ele é alterado.
  Stream<Map<String, dynamic>> get documentStream => _documentController.stream;

  /// O stream de dados de presença.
  ///
  /// Emite o mapa completo de dados de presença sempre que um usuário
  /// entra, sai ou move o cursor.
  Stream<Map<String, Map<String, dynamic>>> get presenceStream =>
      _presenceController.stream;

  /// Busca o estado inicial do documento da nota.
  Future<Map<String, dynamic>> getDocument(String noteId) async {
    // Em uma implementação real, `noteId` seria usado para buscar o
    // documento correto no Firestore.
    return _documentData;
  }

  /// Atualiza o conteúdo do documento da nota.
  ///
  /// Esta função seria chamada sempre que o usuário local fizesse uma edição.
  Future<void> updateDocument(String noteId, DocumentModel content) async {
    _documentData['content'] = content.toJson();
    // Emite o novo estado do documento para todos os ouvintes do stream.
    _documentController.add(_documentData);
  }

  /// Atualiza a presença e a posição do cursor do usuário.
  ///
  /// `userId` deve ser um identificador único para o colaborador.
  /// `cursorData` deve conter informações como a posição do cursor,
  /// o nome do usuário e a cor do cursor.
  Future<void> updateUserPresence(
    String noteId,
    String userId,
    Map<String, dynamic> cursorData,
  ) async {
    _presenceData[userId] = cursorData;
    // Emite o estado atualizado da presença para todos os ouvintes.
    _presenceController.add(_presenceData);
  }

  /// Remove um usuário do rastreamento de presença.
  ///
  /// Isso seria chamado quando um usuário se desconectasse da nota.
  Future<void> removeUserPresence(String noteId, String userId) async {
    _presenceData.remove(userId);
    _presenceController.add(_presenceData);
  }

  /// Libera os recursos do serviço.
  void dispose() {
    unawaited(_documentController.close());
    unawaited(_presenceController.close());
  }
}
