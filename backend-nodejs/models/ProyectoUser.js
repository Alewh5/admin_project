const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ProyectoUser = sequelize.define('ProyectoUser', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  proyectoId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false,
  },
  rolEnProyecto: {
    type: DataTypes.STRING,
    allowNull: true,
  }
}, {
  timestamps: true,
  tableName: 'proyecto_users'
});

const Proyecto = require('./Proyecto');
const User = require('./user');

Proyecto.belongsToMany(User, { through: ProyectoUser, foreignKey: 'proyectoId', otherKey: 'userId', as: 'equipo' });
User.belongsToMany(Proyecto, { through: ProyectoUser, foreignKey: 'userId', otherKey: 'proyectoId', as: 'proyectosAsignados' });

module.exports = ProyectoUser;
