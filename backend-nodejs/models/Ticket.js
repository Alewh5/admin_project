const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Room = require('./Room');

const Ticket = sequelize.define('Ticket', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  ticketNumber: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  roomId: {
    type: DataTypes.STRING,
    allowNull: false,
    references: {
      model: Room,
      key: 'id',
    }
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: true,
  },
  status: {
    type: DataTypes.INTEGER,
    allowNull: false,
    defaultValue: 0,
  }
}, {
  timestamps: true,
  tableName: 'tickets'
});

Ticket.belongsTo(Room, { foreignKey: 'roomId', as: 'room' });
Room.hasMany(Ticket, { foreignKey: 'roomId', as: 'tickets' });

module.exports = Ticket;
