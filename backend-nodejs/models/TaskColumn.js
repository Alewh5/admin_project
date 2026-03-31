const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Proyecto = require('./Proyecto');

const TaskColumn = sequelize.define('TaskColumn', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  proyectoId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  nombre: {
    type: DataTypes.STRING,
    allowNull: false
  },
  color: {
    type: DataTypes.STRING,
    defaultValue: '#000000'
  },
  orden: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  }
}, {
  timestamps: true,
  tableName: 'task_columns'
});

TaskColumn.belongsTo(Proyecto, { foreignKey: 'proyectoId', as: 'proyecto' });
Proyecto.hasMany(TaskColumn, { foreignKey: 'proyectoId', as: 'columns' });

module.exports = TaskColumn;
