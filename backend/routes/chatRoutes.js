const router = require('express').Router();
const verifyToken = require('../middleware/verifyToken');
const chatController = require('../controllers/chatController');

router.get('/chat/notificacoes', verifyToken, chatController.getNotificacoes);
router.get('/chat/:reclamacao_id', verifyToken, chatController.getMensagens);
router.post('/chat/:reclamacao_id', verifyToken, chatController.enviarMensagem);

module.exports = router;
