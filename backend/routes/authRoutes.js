const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/authController');
const verifyToken = require('../middleware/verifyToken');
const validate = require('../middleware/validate');

const registrarRules = [
  body('nome').trim().notEmpty().withMessage('Nome é obrigatório.'),
  body('email').isEmail().normalizeEmail().withMessage('Email inválido.'),
  body('senha').isLength({ min: 6 }).withMessage('Senha deve ter no mínimo 6 caracteres.'),
  body('tipo').isIn(['empresa', 'consumidor']).withMessage('Tipo deve ser "empresa" ou "consumidor".'),
];

const loginRules = [
  body('email').isEmail().normalizeEmail().withMessage('Email inválido.'),
  body('senha').notEmpty().withMessage('Senha é obrigatória.'),
];

router.post('/registrar', registrarRules, validate, authController.registrar);
router.post('/login', loginRules, validate, authController.login);
router.get('/me', verifyToken, authController.me);

module.exports = router;
