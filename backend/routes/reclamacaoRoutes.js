const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const reclamacaoController = require('../controllers/reclamacaoController');
const verifyToken = require('../middleware/verifyToken');
const validate = require('../middleware/validate');

const criarRules = [
  body('empresa_cnpj')
    .matches(/^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/)
    .withMessage('CNPJ inválido. Use o formato 00.000.000/0000-00.'),
  body('numero_pedido').trim().notEmpty().withMessage('Número do pedido é obrigatório.'),
  body('motivo').trim().isLength({ min: 10 }).withMessage('Motivo deve ter no mínimo 10 caracteres.'),
  body('forma_solucao').optional().trim(),
];

router.post('/reclamacao', verifyToken, criarRules, validate, reclamacaoController.criar);
router.get('/reclamacao/empresa', verifyToken, reclamacaoController.getByEmpresa);
router.get('/reclamacao/consumidor', verifyToken, reclamacaoController.getByConsumidor);
router.put('/reclamacao/:id/status', verifyToken, reclamacaoController.updateStatus);

module.exports = router;
