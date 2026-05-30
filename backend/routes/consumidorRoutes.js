const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const consumidorController = require('../controllers/consumidorController');
const verifyToken = require('../middleware/verifyToken');
const validate = require('../middleware/validate');
const { requireConsumidor } = require('../middleware/requireTipo');

const addConsumidorRules = [
  body('nome').trim().notEmpty().withMessage('Nome é obrigatório.'),
  body('cpf')
    .matches(/^\d{3}\.\d{3}\.\d{3}-\d{2}$/)
    .withMessage('CPF inválido. Use o formato 000.000.000-00.'),
  body('email').isEmail().normalizeEmail().withMessage('Email inválido.'),
  body('telefone').optional().trim(),
];

router.post('/add-consumidor', verifyToken, requireConsumidor, addConsumidorRules, validate, consumidorController.addConsumidor);

// Buscar perfil do consumidor logado
router.get('/consumidor/perfil', verifyToken, requireConsumidor, consumidorController.getPerfil);

const updatePerfilRules = [
  body('nome').trim().notEmpty().withMessage('Nome é obrigatório.'),
  body('email').isEmail().normalizeEmail().withMessage('Email inválido.'),
  body('telefone').optional().trim(),
];

router.put('/consumidor/perfil', verifyToken, requireConsumidor, updatePerfilRules, validate, consumidorController.updatePerfil);

module.exports = router;
