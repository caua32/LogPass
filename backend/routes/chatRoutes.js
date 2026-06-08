const router = require('express').Router();
const verifyToken = require('../middleware/verifyToken');
const chatController = require('../controllers/chatController');

module.exports = (upload) => {
  router.get('/chat/notificacoes', verifyToken, chatController.getNotificacoes);
  router.get('/chat/:reclamacao_id', verifyToken, chatController.getMensagens);
  router.post('/chat/:reclamacao_id', verifyToken, chatController.enviarMensagem);
  router.post('/chat/:reclamacao_id/imagem', verifyToken, upload.single('imagem'), chatController.enviarImagem);
  return router;
};
