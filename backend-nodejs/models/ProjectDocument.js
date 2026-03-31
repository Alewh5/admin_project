const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Proyecto = require('./Proyecto');
const Task = require('./Task');

const ProjectDocument = sequelize.define('ProjectDocument', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  proyectoId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  taskId: {
    type: DataTypes.INTEGER,
    allowNull: true
  },
  nombre: {
    type: DataTypes.STRING,
    allowNull: false
  },
  ruta: {
    type: DataTypes.STRING,
    allowNull: false
  },
  tipo: {
    type: DataTypes.STRING,
    allowNull: true
  }
}, {
  timestamps: true,
  tableName: 'project_documents'
});

ProjectDocument.belongsTo(Proyecto, { foreignKey: 'proyectoId', as: 'proyecto' });
ProjectDocument.belongsTo(Task, { foreignKey: 'taskId', as: 'task' });
Proyecto.hasMany(ProjectDocument, { foreignKey: 'proyectoId', as: 'documentos' });
Task.hasMany(ProjectDocument, { foreignKey: 'taskId', as: 'documentos' });

module.exports = ProjectDocument;
