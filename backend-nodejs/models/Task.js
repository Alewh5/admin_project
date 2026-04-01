const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const TaskColumn = require('./TaskColumn');
const Proyecto = require('./Proyecto');

const Task = sequelize.define('Task', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  proyectoId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  columnId: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  sprintId: {
    type: DataTypes.INTEGER,
    allowNull: true,
    references: {
      model: 'sprints',
      key: 'id'
    }
  },
  titulo: {
    type: DataTypes.STRING,
    allowNull: false
  },
  descripcion: {
    type: DataTypes.TEXT,
    allowNull: true
  },
  prioridad: {
    type: DataTypes.STRING,
    defaultValue: '3'
  },
  dificultad: {
    type: DataTypes.INTEGER,
    defaultValue: 3
  },
  estimacion: {
    type: DataTypes.DECIMAL(5, 2),
    allowNull: true
  },
  fechaInicioT: {
    type: DataTypes.DATE,
    allowNull: true
  },
  fechaFinT: {
    type: DataTypes.DATE,
    allowNull: true
  },
  fechaRealInicio: {
    type: DataTypes.DATE,
    allowNull: true
  },
  fechaRealFin: {
    type: DataTypes.DATE,
    allowNull: true
  },
  estado: {
    type: DataTypes.STRING,
    defaultValue: 'Por hacer'
  },
  fechaVencimiento: {
    type: DataTypes.DATE,
    allowNull: true
  },
  orden: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  }
}, {
  timestamps: true,
  tableName: 'tasks'
});

Task.belongsTo(Proyecto, { foreignKey: 'proyectoId', as: 'proyecto' });
Task.belongsTo(TaskColumn, { foreignKey: 'columnId', as: 'column' });
// Requerimos localmente para evitar circular dependency al inicio
const Sprint = require('./sprint');
Task.belongsTo(Sprint, { foreignKey: 'sprintId', as: 'sprint' });
Sprint.hasMany(Task, { foreignKey: 'sprintId', as: 'tasks' });

Proyecto.hasMany(Task, { foreignKey: 'proyectoId', as: 'tasks' });
TaskColumn.hasMany(Task, { foreignKey: 'columnId', as: 'tasks' });

module.exports = Task;
