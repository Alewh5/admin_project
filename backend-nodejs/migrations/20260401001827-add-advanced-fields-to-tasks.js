'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
    await queryInterface.addColumn('tasks', 'dificultad', {
      type: Sequelize.INTEGER,
      allowNull: true,
      defaultValue: 3
    });
    await queryInterface.addColumn('tasks', 'estimacion', {
      type: Sequelize.DECIMAL(5, 2),
      allowNull: true
    });
    await queryInterface.addColumn('tasks', 'fechaInicioT', {
      type: Sequelize.DATE,
      allowNull: true
    });
    await queryInterface.addColumn('tasks', 'fechaFinT', {
      type: Sequelize.DATE,
      allowNull: true
    });
    await queryInterface.addColumn('tasks', 'fechaRealInicio', {
      type: Sequelize.DATE,
      allowNull: true
    });
    await queryInterface.addColumn('tasks', 'fechaRealFin', {
      type: Sequelize.DATE,
      allowNull: true
    });
    // Convertir prioridad existente a STRING para evitar problemas con ENUM.
    await queryInterface.changeColumn('tasks', 'prioridad', {
      type: Sequelize.STRING,
      allowNull: true,
      defaultValue: '3'
    });
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.removeColumn('tasks', 'dificultad');
    await queryInterface.removeColumn('tasks', 'estimacion');
    await queryInterface.removeColumn('tasks', 'fechaInicioT');
    await queryInterface.removeColumn('tasks', 'fechaFinT');
    await queryInterface.removeColumn('tasks', 'fechaRealInicio');
    await queryInterface.removeColumn('tasks', 'fechaRealFin');
    await queryInterface.changeColumn('tasks', 'prioridad', {
      type: Sequelize.ENUM('Baja', 'Media', 'Alta', 'Urgente'),
      defaultValue: 'Media'
    });
  }
};
