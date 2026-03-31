const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Ticket = require('./Ticket');

const TicketImage = sequelize.define('TicketImage', {
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
    fileUrl: {
        type: DataTypes.STRING,
        allowNull: false
    }
}, {
    timestamps: true,
    tableName: 'ticket_images'
});

Ticket.hasMany(TicketImage, { foreignKey: 'ticketId', as: 'ticketImages' });
TicketImage.belongsTo(Ticket, { foreignKey: 'ticketId', as: 'ticket' });

module.exports = TicketImage;
