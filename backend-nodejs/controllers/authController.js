const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/user');
const Role = require('../models/role');
const logger = require('../src/logger');

const generateTokens = (user) => {
    const payload = { id: user.id, roleId: user.roleId, role: user.role.name };
    const accessToken = jwt.sign(payload, process.env.JWT_ACCESS_SECRET, { expiresIn: '15m' });
    const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, { expiresIn: '30d' });
    return { accessToken, refreshToken };
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({
            where: { email },
            include: [{ model: Role, as: 'role' }]
        });

        if (!user) {
            logger.warn(`Intento de login fallido: usuario no encontrado (email: ${email})`);
            return res.status(401).json({ error: 'Credenciales inválidas.' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            logger.warn(`Intento de login fallido: contraseña incorrecta (email: ${email})`);
            return res.status(401).json({ error: 'Credenciales inválidas.' });
        }

        const { accessToken, refreshToken } = generateTokens(user);

        await user.update({ isActive: true, refreshToken });

        logger.info(`Inicio de sesión exitoso para el usuario ID=${user.id} (${user.email})`);
        res.json({
            accessToken,
            refreshToken,
            user: {
                id: user.id,
                firstName: user.firstName,
                lastName: user.lastName,
                email: user.email,
                role: user.role.name,
                isActive: user.isActive
            }
        });
    } catch (error) {
        logger.error(`Error en el inicio de sesión: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const refreshToken = async (req, res) => {
    try {
        const { token } = req.body;

        if (!token) {
            return res.status(403).json({ error: 'El refresh token es requerido.' });
        }

        const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);

        const user = await User.findOne({
            where: { id: decoded.id, refreshToken: token },
            include: [{ model: Role, as: 'role' }]
        });

        if (!user) {
            return res.status(403).json({ error: 'Refresh token inválido o revocado.' });
        }

        const tokens = generateTokens(user);

        await user.update({ refreshToken: tokens.refreshToken });

        res.json({
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken
        });
    } catch (error) {
        logger.warn(`Refresh token inválido o expirado: ${error.message}`);
        return res.status(401).json({ error: 'Refresh token expirado o inválido.' });
    }
};

const logout = async (req, res) => {
    try {
        const { userId } = req.body;
        await User.update({ isActive: false, refreshToken: null }, { where: { id: userId } });
        logger.info(`Cierre de sesión para el usuario ID=${userId}`);
        res.json({ message: 'Sesión cerrada correctamente.' });
    } catch (error) {
        logger.error(`Error al cerrar sesión: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

module.exports = {
    login,
    refreshToken,
    logout
};