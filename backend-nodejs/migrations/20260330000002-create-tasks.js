'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('tasks', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      proyectoId: {
        type: Sequelize.INTEGER,
        allowNull: false,
        references: {
          model: 'proyectos',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE'
      },
      columnId: {
        type: Sequelize.INTEGER,
        allowNull: true,
        references: {
          model: 'task_columns',
          key: 'id'
        },
        onUpdate: 'CASCADE',
        onDelete: 'SET NULL'
      },
      titulo: {
        type: Sequelize.STRING,
        allowNull: false
      },
      descripcion: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      prioridad: {
        type: Sequelize.ENUM('Baja', 'Media', 'Alta', 'Urgente'),
        defaultValue: 'Media'
      },
      estado: {
        type: Sequelize.STRING,
        defaultValue: 'Por hacer'
      },
      fechaVencimiento: {
        type: Sequelize.DATE,
        allowNull: true
      },
      orden: {
        type: Sequelize.INTEGER,
        defaultValue: 0
      },
      createdAt: {
        allowNull: false,
        type: Sequelize.DATE
      },
      updatedAt: {
        allowNull: false,
        type: Sequelize.DATE
      }
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('tasks');
  }
};
