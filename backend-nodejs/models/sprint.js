const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Proyecto = require('./Proyecto');

const Sprint = sequelize.define('Sprint', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  proyectoId: {
    type: DataTypes.INTEGER,
    allowNull: false,
    references: {
      model: 'proyectos',
      key: 'id'
    }
  },
  nombre: {
    type: DataTypes.STRING,
    allowNull: false
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  estado: {
    type: DataTypes.INTEGER,
    defaultValue: 0 // 0: Planeado, 1: Activo, 2: Terminado
  },
  fechaInicio: {
    type: DataTypes.DATE,
    allowNull: true
  },
  fechaFin: {
    type: DataTypes.DATE,
    allowNull: true
  }
}, {
  timestamps: true,
  tableName: 'sprints'
});

Sprint.belongsTo(Proyecto, { foreignKey: 'proyectoId', as: 'proyecto' });
Proyecto.hasMany(Sprint, { foreignKey: 'proyectoId', as: 'sprints' });

module.exports = Sprint;