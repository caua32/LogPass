const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const empresaController = require('../controllers/empresaController');
const verifyToken = require('../middleware/verifyToken');
const validate = require('../middleware/validate');

const addEmpresaRules = [
  body('nomeempresa').trim().notEmpty().withMessage('Nome da empresa é obrigatório.'),
  body('cnpj')
    .matches(/^\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}$/)
    .withMessage('CNPJ inválido. Use o formato 00.000.000/0000-00.'),
  body('contato').optional().trim(),
  body('logradouro').optional().trim(),
  body('numero').optional().trim(),
  body('bairro').optional().trim(),
  body('cidade').optional().trim(),
  body('cep').optional().trim(),
];

router.post('/add-empresa', verifyToken, addEmpresaRules, validate, empresaController.addEmpresa);

// Buscar perfil da empresa logada
router.get('/empresa/perfil', verifyToken, empresaController.getPerfil);

// Atualizar perfil da empresa
router.put('/empresa/perfil', verifyToken, empresaController.updatePerfil);

module.exports = router;
