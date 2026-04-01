const bcrypt = require('bcryptjs');
const User = require('../models/user');
const Role = require('../models/role');
const logger = require('../src/logger');

const getUsers = async (req, res) => {
    try {
        const usuarios = await User.findAll({
            include: [{ model: Role, as: 'role' }],
            attributes: { exclude: ['password', 'refreshToken'] }
        });
        res.json(usuarios);
    } catch (error) {
        logger.error(`Error al obtener usuarios: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const getInvitableUsers = async (req, res) => {
    try {
        const { Op } = require('sequelize');
        
        const usuarios = await User.findAll({
            where: {
                roleId: {
                    [Op.notIn]: [1, 2, 3, 4]
                }
            },
            include: [{ model: Role, as: 'role' }],
            attributes: { exclude: ['password', 'refreshToken'] }
        });
        res.json(usuarios);
    } catch (error) {
        logger.error(`Error al obtener usuarios invitables: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const createUser = async (req, res) => {
    try {
        const { firstName, lastName, email, password, roleId } = req.body;

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const nuevoUsuario = await User.create({
            firstName,
            lastName,
            email,
            password: hashedPassword,
            roleId,
            isActive: false
        });

        logger.info(`Usuario creado: ${email} (ID=${nuevoUsuario.id})`);
        res.status(201).json({ message: 'Usuario creado exitosamente.', user: nuevoUsuario });
    } catch (error) {
        if (error.name === 'SequelizeUniqueConstraintError') {
            return res.status(409).json({ error: 'Ya existe un usuario con ese correo electrónico.' });
        }
        logger.error(`Error al crear usuario: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { firstName, lastName, email, password, roleId } = req.body;

        const usuario = await User.findByPk(id);
        if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado.' });

        const updateData = { firstName, lastName, email, roleId };

        if (password && password.trim() !== '') {
            const salt = await bcrypt.genSalt(10);
            updateData.password = await bcrypt.hash(password, salt);
        }

        await usuario.update(updateData);
        logger.info(`Usuario actualizado: ID=${id}`);
        res.json({ message: 'Usuario actualizado exitosamente.', user: usuario });
    } catch (error) {
        logger.error(`Error al actualizar usuario ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const usuario = await User.findByPk(id);
        if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado.' });

        await usuario.destroy();
        logger.info(`Usuario eliminado: ID=${id}`);
        res.json({ message: 'Usuario eliminado exitosamente.' });
    } catch (error) {
        logger.error(`Error al eliminar usuario ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const toggleUserStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const usuario = await User.findByPk(id);
        if (!usuario) return res.status(404).json({ error: 'Usuario no encontrado.' });

        await usuario.update({ isActive: !usuario.isActive });
        logger.info(`Estado del usuario ID=${id} cambiado a ${usuario.isActive}`);
        res.json({ message: 'Estado actualizado.', isActive: usuario.isActive });
    } catch (error) {
        logger.error(`Error al cambiar estado del usuario ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const uploadAvatar = async (req, res) => {
    try {
        const { id } = req.params;
        const usuario = await User.findByPk(id);
        
        if (!usuario) {
            return res.status(404).json({ error: 'Usuario no encontrado.' });
        }

        if (!req.file) {
            return res.status(400).json({ error: 'No se envió ninguna imagen.' });
        }

        const avatarUrl = `/uploads/avatars/${req.file.filename}`;
        await usuario.update({ avatar: avatarUrl });

        res.json({ message: 'Avatar actualizado exitosamente.', avatar: avatarUrl, user: usuario });
    } catch (error) {
        logger.error(`Error al subir avatar: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

module.exports = {
    getUsers,
    getInvitableUsers,
    createUser,
    updateUser,
    deleteUser,
    toggleUserStatus,
    uploadAvatar
};