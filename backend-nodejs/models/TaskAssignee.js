const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const Task = require('./Task');
const User = require('./user');

const TaskAssignee = sequelize.define('TaskAssignee', {
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
  }
}, {
  timestamps: true,
  tableName: 'task_assignees'
});

Task.belongsToMany(User, { through: TaskAssignee, foreignKey: 'taskId', otherKey: 'userId', as: 'assignees' });
User.belongsToMany(Task, { through: TaskAssignee, foreignKey: 'userId', otherKey: 'taskId', as: 'assignedTasks' });

module.exports = TaskAssignee;
