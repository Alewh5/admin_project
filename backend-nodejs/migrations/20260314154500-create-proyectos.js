'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('proyectos', {
      id: {
        type: Sequelize.INTEGER,
        autoIncrement: true,
        primaryKey: true,
        allowNull: false
      },
      nombre: {
        type: Sequelize.STRING,
        allowNull: false
      },
      descripcion: {
        type: Sequelize.TEXT,
        allowNull: true
      },
      estimacionInicio: {
        type: Sequelize.DATE,
        allowNull: true
      },
      estimacionFin: {
        type: Sequelize.DATE,
        allowNull: true
      },
      encargadoProyecto: {
        type: Sequelize.STRING,
        allowNull: true
      },
      estado: {
        type: Sequelize.ENUM('Activo', 'En Desarrollo', 'Bloqueo', 'Dado de Baja', 'Inactivo'),
        allowNull: false,
        defaultValue: 'Inactivo'
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
    await queryInterface.dropTable('proyectos');
  }
};
