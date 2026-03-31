const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Task = require('./Task');
const User = require('./user');

const TaskComment = sequelize.define('TaskComment', {
  id: {
    type: DataTypes.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  taskId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  userId: {
    type: DataTypes.INTEGER,
    allowNull: false
  },
  contenido: {
    type: DataTypes.TEXT,
    allowNull: false
  }
}, {
  timestamps: true,
  tableName: 'task_comments'
});

TaskComment.belongsTo(Task, { foreignKey: 'taskId', as: 'task' });
TaskComment.belongsTo(User, { foreignKey: 'userId', as: 'user' });
Task.hasMany(TaskComment, { foreignKey: 'taskId', as: 'comments' });
User.hasMany(TaskComment, { foreignKey: 'userId', as: 'comments' });

module.exports = TaskComment;
