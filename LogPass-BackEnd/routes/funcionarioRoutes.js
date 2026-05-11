const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const funcionarioController = require('../controllers/funcionarioController');
const verifyToken = require('../middleware/verifyToken');
const requireAdmin = require('../middleware/requireAdmin');
const validate = require('../middleware/validate');

const loginRules = [
  body('email').isEmail().normalizeEmail().withMessage('Email inválido.'),
  body('senha').notEmpty().withMessage('Senha é obrigatória.'),
];

router.post('/admin/login', loginRules, validate, funcionarioController.loginFuncionario);
router.get('/admin/reclamacoes', verifyToken, requireAdmin, funcionarioController.getTodasReclamacoes);

module.exports = router;
