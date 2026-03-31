const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Ticket = require('./Ticket');

const TicketReply = sequelize.define('TicketReply', {
    id: {
        type: DataTypes.INTEGER,
        autoIncrement: true,
        primaryKey: true
    },
    ticketId: {
        type: DataTypes.INTEGER,
        allowNull: false,
        references: {
            model: Ticket,
            key: 'id'
        },
        onDelete: 'CASCADE'
    },
    message: {
        type: DataTypes.TEXT,
        allowNull: false
    },
    agentName: {
        type: DataTypes.STRING,
        allowNull: false,
        defaultValue: 'Agente'
    }
}, {
    timestamps: true,
    tableName: 'ticket_replies'
});

Ticket.hasMany(TicketReply, { foreignKey: 'ticketId', as: 'ticketReplies' });
TicketReply.belongsTo(Ticket, { foreignKey: 'ticketId', as: 'ticket' });

module.exports = TicketReply;
