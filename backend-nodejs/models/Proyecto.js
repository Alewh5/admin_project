const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Proyecto = sequelize.define('Proyecto', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
    allowNull: false
  },
  nombre: {
    type: DataTypes.STRING,
    allowNull: false
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  estimacionInicio: {
    type: DataTypes.DATE,
    allowNull: true
  },
  estimacionFin: {
    type: DataTypes.DATE,
    allowNull: true
  },
  encargadoProyecto: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  estado: {
    type: DataTypes.ENUM('Activo', 'En Desarrollo', 'Bloqueo', 'Dado de Baja', 'Inactivo'),
    allowNull: false,
    defaultValue: 'Inactivo'
  }
}, {
  timestamps: true,
  tableName: 'proyectos'
});

module.exports = Proyecto;
