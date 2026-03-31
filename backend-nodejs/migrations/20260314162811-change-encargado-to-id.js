'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.sequelize.query('UPDATE proyectos SET encargadoProyecto = NULL');

    await queryInterface.changeColumn('proyectos', 'encargadoProyecto', {
      type: Sequelize.INTEGER,
      allowNull: true,
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.changeColumn('proyectos', 'encargadoProyecto', {
      type: Sequelize.STRING,
      allowNull: true,
    });
  }
};
