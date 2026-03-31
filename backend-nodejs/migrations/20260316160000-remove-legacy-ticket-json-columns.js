'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.removeColumn('tickets', 'replies');
    await queryInterface.removeColumn('tickets', 'images');
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.addColumn('tickets', 'replies', {
      type: Sequelize.JSON,
      allowNull: true,
      defaultValue: []
    });
    await queryInterface.addColumn('tickets', 'images', {
      type: Sequelize.JSON,
      allowNull: true,
      defaultValue: []
    });
  }
};
