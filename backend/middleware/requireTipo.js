exports.requireConsumidor = (req, res, next) => {
  if (req.user.tipo !== 'consumidor')
    return res.status(403).json({ message: 'Acesso restrito a consumidores.' });
  next();
};

exports.requireEmpresa = (req, res, next) => {
  if (req.user.tipo !== 'empresa')
    return res.status(403).json({ message: 'Acesso restrito a empresas.' });
  next();
};
