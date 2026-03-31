const jwt = require('jsonwebtoken');
const logger = require('../src/logger');

const verifyToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(403).json({ error: 'Token de acceso no proporcionado.' });
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
        req.user = decoded;
        next();
    } catch (error) {
        logger.warn(`Intento de acceso con token inválido: ${error.message}`);
        return res.status(401).json({ error: 'Token inválido o expirado.' });
    }
};

const checkRole = (roles) => {
    return (req, res, next) => {
        if (!req.user || !roles.includes(req.user.role)) {
            logger.warn(`Acceso denegado al usuario ID=${req.user?.id} con rol=${req.user?.role}. Roles permitidos: ${roles.join(', ')}`);
            return res.status(403).json({ error: 'Acceso denegado: permisos insuficientes.' });
        }
        next();
    };
};

module.exports = {
    verifyToken,
    checkRole
};