const { Op } = require('sequelize');
const sequelize = require('../config/database');
const Room = require('../models/Room');
const Ticket = require('../models/Ticket');
const Message = require('../models/Message');
const logger = require('../src/logger');

exports.getSummary = async (req, res) => {
    try {
        const hoy = new Date();
        hoy.setHours(0, 0, 0, 0);

        const [
            chatsActivos,
            chatsSinAsignar,
            ticketsAbiertos,
            ticketsEnProgreso,
            ticketsResueltos,
            mensajesHoy,
            promedioQuery
        ] = await Promise.all([
            Room.count({ where: { status: ['open', 'in_progress'] } }),
            Room.count({ where: { status: ['open', 'in_progress'], agentId: null } }),
            Ticket.count({ where: { status: 0 } }),
            Ticket.count({ where: { status: 1 } }),
            Ticket.count({ where: { status: 2, updatedAt: { [Op.gte]: hoy } } }),
            Message.count({ where: { createdAt: { [Op.gte]: hoy } } }),
            Room.findOne({
                attributes: [
                    [sequelize.fn('AVG', sequelize.col('rating')), 'promedio']
                ],
                where: { rating: { [Op.not]: null } }
            })
        ]);

        const promedioCalificacion = promedioQuery && promedioQuery.dataValues.promedio
            ? parseFloat(promedioQuery.dataValues.promedio).toFixed(1)
            : '0.0';

        res.json({
            chatsActivos,
            chatsSinAsignar,
            ticketsAbiertos,
            ticketsEnProgreso,
            ticketsResueltos,
            mensajesHoy,
            promedioCalificacion,
        });
    } catch (error) {
        logger.error(`Error al obtener resumen de reportes: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.getAgentRanking = async (req, res) => {
    const { period } = req.query;
    let dateFilter = new Date();

    if (period === '7d') dateFilter.setDate(dateFilter.getDate() - 7);
    else if (period === '15d') dateFilter.setDate(dateFilter.getDate() - 15);
    else if (period === '1m') dateFilter.setMonth(dateFilter.getMonth() - 1);
    else if (period === '3m') dateFilter.setMonth(dateFilter.getMonth() - 3);
    else if (period === '1y') dateFilter.setFullYear(dateFilter.getFullYear() - 1);
    else dateFilter = new Date(0);

    try {
        const ranking = await Room.findAll({
            attributes: [
                'agentName',
                [sequelize.fn('AVG', sequelize.col('rating')), 'promedio'],
                [sequelize.fn('COUNT', sequelize.col('id')), 'totalChats']
            ],
            where: {
                rating: { [Op.not]: null },
                updatedAt: { [Op.gte]: dateFilter },
                agentName: { [Op.not]: null }
            },
            group: ['agentName'],
            order: [[sequelize.literal('promedio'), 'DESC']]
        });
        res.json(ranking);
    } catch (error) {
        logger.error(`Error al obtener ranking: ${error.message}`);
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};