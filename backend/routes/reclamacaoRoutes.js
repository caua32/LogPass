const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const reclamacaoController = require('../controllers/reclamacaoController');
const {
  editarReclamacaoConsumidor,
  deletarReclamacaoConsumidor,
  avaliarReclamacao,
} = reclamacaoController;
const verifyToken = require('../middleware/verifyToken');
const validate = require('../middleware/validate');
const requireAdmin = require('../middleware/requireAdmin');
const { requireConsumidor, requireEmpresa } = require('../middleware/requireTipo');

const criarRules = [
  body('empresa_cnpj')
    .matches(/^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/)
    .withMessage('CNPJ inválido. Use o formato 00.000.000/0000-00.'),
  body('numero_pedido').trim().notEmpty().withMessage('Número do pedido é obrigatório.'),
  body('motivo').trim().isLength({ min: 10 }).withMessage('Motivo deve ter no mínimo 10 caracteres.'),
  body('forma_solucao').optional().trim(),
];

router.post('/reclamacao', verifyToken, requireConsumidor, criarRules, validate, reclamacaoController.criar);
router.get('/reclamacao/empresa', verifyToken, requireEmpresa, reclamacaoController.getByEmpresa);
router.get('/reclamacao/consumidor', verifyToken, requireConsumidor, reclamacaoController.getByConsumidor);
router.put('/reclamacao/:id/status', verifyToken, requireAdmin, reclamacaoController.updateStatus);
router.put('/reclamacao/:id',          verifyToken, requireConsumidor, editarReclamacaoConsumidor);
router.delete('/reclamacao/:id',       verifyToken, requireConsumidor, deletarReclamacaoConsumidor);
router.post('/reclamacao/:id/avaliacao', verifyToken, requireConsumidor, avaliarReclamacao);

module.exports = router;
