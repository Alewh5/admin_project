const { Op, sequelize: _seq } = require('sequelize');
const sequelize = require('../config/database');
const Ticket = require('../models/Ticket');
const TicketReply = require('../models/TicketReply');
const TicketImage = require('../models/TicketImage');
const Room = require('../models/Room');
const crypto = require('crypto');
const logger = require('../src/logger');

const MAX_REINTENTOS = 5;

const generarNumeroTicketUnico = async (transaction) => {
    for (let intento = 1; intento <= MAX_REINTENTOS; intento++) {
        const numero = `TKN-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
        const existente = await Ticket.findOne({ where: { ticketNumber: numero }, transaction });
        if (!existente) {
            logger.debug(`Número de ticket generado: ${numero} (intento ${intento}/${MAX_REINTENTOS})`);
            return numero;
        }
        logger.warn(`Colisión de número de ticket: ${numero}. Reintentando... (intento ${intento}/${MAX_REINTENTOS})`);
    }
    throw new Error('No se pudo generar un número de ticket único después de varios intentos.');
};

exports.createTicket = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { roomId, title, description, status, images } = req.body;

        const ticketNumber = await generarNumeroTicketUnico(t);

        const nuevoTicket = await Ticket.create({
            ticketNumber,
            roomId,
            title,
            description,
            status: status !== undefined ? status : 0,
        }, { transaction: t });

        if (images && Array.isArray(images) && images.length > 0) {
            const imagenesData = images.map((url) => ({ ticketId: nuevoTicket.id, fileUrl: url }));
            await TicketImage.bulkCreate(imagenesData, { transaction: t });
        }

        await t.commit();
        logger.info(`Ticket creado: ${ticketNumber} (ID=${nuevoTicket.id})`);

        const ticketConRelaciones = await Ticket.findByPk(nuevoTicket.id, {
            include: [
                { model: TicketReply, as: 'ticketReplies' },
                { model: TicketImage, as: 'ticketImages' }
            ]
        });

        res.status(201).json(ticketConRelaciones);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al crear ticket: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.getTicketsByRoom = async (req, res) => {
    try {
        const { roomId } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const offset = (page - 1) * limit;

        const { count, rows } = await Ticket.findAndCountAll({
            where: { roomId },
            include: [
                { model: TicketReply, as: 'ticketReplies' },
                { model: TicketImage, as: 'ticketImages' }
            ],
            order: [['createdAt', 'DESC']],
            limit,
            offset
        });

        res.status(200).json({
            totalItems: count,
            totalPages: Math.ceil(count / limit),
            currentPage: page,
            tickets: rows
        });
    } catch (error) {
        logger.error(`Error al obtener tickets de la sala: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.updateTicketStatus = async (req, res) => {
    try {
        const { id } = req.params;
        const { status } = req.body;

        const ticket = await Ticket.findByPk(id);

        if (!ticket) {
            return res.status(404).json({ error: 'Ticket no encontrado.' });
        }

        await ticket.update({ status });
        logger.info(`Estado del ticket ID=${id} actualizado a ${status}`);
        res.status(200).json(ticket);
    } catch (error) {
        logger.error(`Error al actualizar estado del ticket: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.addTicketReply = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { id } = req.params;
        const { message, agentName, newStatus } = req.body;

        const ticket = await Ticket.findByPk(id, { transaction: t });

        if (!ticket) {
            await t.rollback();
            return res.status(404).json({ error: 'Ticket no encontrado.' });
        }

        const nuevaRespuesta = await TicketReply.create({
            ticketId: ticket.id,
            message,
            agentName: agentName || 'Agente'
        }, { transaction: t });

        if (newStatus !== undefined) {
            await ticket.update({ status: newStatus }, { transaction: t });
        }

        await t.commit();
        logger.info(`Respuesta agregada al ticket ID=${id} por ${agentName || 'Agente'}`);

        const ticketActualizado = await Ticket.findByPk(id, {
            include: [
                { model: TicketReply, as: 'ticketReplies' },
                { model: TicketImage, as: 'ticketImages' }
            ]
        });

        res.status(200).json(ticketActualizado);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al agregar respuesta al ticket: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.getAllTickets = async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;
        const search = req.query.search?.trim() || '';

        const ticketWhere = search
            ? { ticketNumber: { [Op.like]: `%${search}%` } }
            : {};

        const roomWhere = search
            ? { email: { [Op.like]: `%${search}%` } }
            : {};

        const { count, rows } = await Ticket.findAndCountAll({
            where: ticketWhere,
            include: [
                {
                    model: Room,
                    as: 'room',
                    attributes: ['id', 'firstName', 'lastName', 'agentName', 'email'],
                    required: false,
                    where: Object.keys(roomWhere).length > 0 ? roomWhere : undefined
                },
                { model: TicketReply, as: 'ticketReplies' },
                { model: TicketImage, as: 'ticketImages' }
            ],
            order: [['createdAt', 'DESC']],
            limit,
            offset,
            subQuery: false,
            distinct: true
        });

        res.status(200).json({
            totalItems: count,
            totalPages: Math.ceil(count / limit),
            currentPage: page,
            tickets: rows
        });
    } catch (error) {
        logger.error(`Error al obtener todos los tickets: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

