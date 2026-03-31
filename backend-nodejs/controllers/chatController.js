const Room = require('../models/Room');
const Message = require('../models/Message');
const logger = require('../src/logger');

const getHistory = async (req, res) => {
    const roomId = req.params.roomId;
    try {
        const historial = await Message.findAll({
            where: { roomId },
            order: [['createdAt', 'ASC']]
        });
        res.json(historial);
    } catch (error) {
        logger.error(`Error al obtener historial de la sala ${roomId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const createRoom = async (req, res) => {
    const { roomId, firstName, lastName, email, reason, originUrl } = req.body;
    try {
        const [room, created] = await Room.findOrCreate({
            where: { id: roomId },
            defaults: {
                status: 'open',
                firstName,
                lastName,
                email,
                reason,
                originUrl
            }
        });
        logger.info(`Sala ${created ? 'creada' : 'encontrada'}: ${room.id} (${email})`);
        res.status(201).json({ roomId: room.id, status: 'ready', room });
    } catch (error) {
        logger.error(`Error al crear la sala: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const getActiveRooms = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const offset = (page - 1) * limit;

        const { count, rows } = await Room.findAndCountAll({
            where: { status: ['open', 'in_progress'] },
            order: [['updatedAt', 'DESC']],
            limit,
            offset
        });

        res.json({
            totalItems: count,
            totalPages: Math.ceil(count / limit),
            currentPage: page,
            rooms: rows
        });
    } catch (error) {
        logger.error(`Error al obtener salas activas: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const getHistoricalRooms = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const agentName = req.query.agentName;
        const offset = (page - 1) * limit;

        const { Op } = require('sequelize');
        const whereClause = { status: 'closed' };

        if (agentName) {
            whereClause.agentName = { [Op.like]: `%${agentName}%` };
        }

        const { count, rows } = await Room.findAndCountAll({
            where: whereClause,
            order: [['updatedAt', 'DESC']],
            limit,
            offset
        });

        res.json({
            totalItems: count,
            totalPages: Math.ceil(count / limit),
            currentPage: page,
            rooms: rows
        });
    } catch (error) {
        logger.error(`Error al obtener salas históricas: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const uploadFile = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No se recibió ningún archivo.' });
        }
        const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
        logger.info(`Archivo subido: ${req.file.filename}`);
        res.status(200).json({ fileUrl });
    } catch (error) {
        logger.error(`Error al subir archivo: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const assignAgent = async (req, res) => {
    const { roomId } = req.params;
    const { agentId, agentName } = req.body;
    try {
        const room = await Room.findByPk(roomId);
        if (!room) {
            return res.status(404).json({ error: 'Sala no encontrada.' });
        }

        room.agentId = agentId;
        room.agentName = agentName;
        await room.save();

        logger.info(`Sala ${roomId} asignada al agente ${agentName} (ID=${agentId})`);
        res.json({ success: true, room });
    } catch (error) {
        logger.error(`Error al asignar agente a la sala ${roomId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

const rateRoom = async (req, res) => {
    const { roomId } = req.params;
    const { rating, feedback } = req.body;
    try {
        const room = await Room.findByPk(roomId);
        if (!room) {
            return res.status(404).json({ error: 'Sala no encontrada.' });
        }

        room.rating = rating;
        room.ratingFeedback = feedback;
        await room.save();

        logger.info(`Sala ${roomId} calificada con ${rating} estrellas.`);
        res.json({ success: true, room });
    } catch (error) {
        logger.error(`Error al calificar la sala ${roomId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

module.exports = {
    getHistory,
    createRoom,
    getActiveRooms,
    getHistoricalRooms,
    uploadFile,
    assignAgent,
    rateRoom
};