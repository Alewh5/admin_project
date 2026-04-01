'use strict';
const bcrypt = require('bcryptjs');

module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.bulkInsert('roles', [
      { id: 1, name: 'ROOT', description: 'Acceso total al sistema matriz', createdAt: new Date(), updatedAt: new Date() },
      { id: 2, name: 'OWNER', description: 'Dueño de la empresa', createdAt: new Date(), updatedAt: new Date() },
      { id: 3, name: 'SUPERVISOR', description: 'Supervisor de agentes', createdAt: new Date(), updatedAt: new Date() },
      { id: 4, name: 'AGENT', description: 'Agente de soporte', createdAt: new Date(), updatedAt: new Date() },
      { id: 5, name: 'DEVELOPER SR', description: 'Desarrollador Senior', createdAt: new Date(), updatedAt: new Date() },
      { id: 6, name: 'DEVELOPER JR', description: 'Desarrollador Junior', createdAt: new Date(), updatedAt: new Date() },
      { id: 7, name: 'QA', description: 'Quality Assurance', createdAt: new Date(), updatedAt: new Date() },
      { id: 8, name: 'DESIGNER', description: 'Diseñador', createdAt: new Date(), updatedAt: new Date() },
      { id: 9, name: 'PROJECT MANAGER', description: 'Project Manager', createdAt: new Date(), updatedAt: new Date() },
      { id: 10, name: 'DBA', description: 'Administrador de Base de Datos', createdAt: new Date(), updatedAt: new Date() },
      { id: 11, name: 'DEVOPS', description: 'DevOps', createdAt: new Date(), updatedAt: new Date() },
      { id: 12, name: 'MARKETING', description: 'Marketing', createdAt: new Date(), updatedAt: new Date() },
      { id: 13, name: 'SALES', description: 'Ventas', createdAt: new Date(), updatedAt: new Date() },
      { id: 14, name: 'HR', description: 'Recursos Humanos', createdAt: new Date(), updatedAt: new Date() },
      { id: 15, name: 'LEGAL', description: 'Legal', createdAt: new Date(), updatedAt: new Date() },
      { id: 16, name: 'FINANCE', description: 'Finanzas', createdAt: new Date(), updatedAt: new Date() },
    ], {});

    const hashedPassword = await bcrypt.hash('123456', 10);

    await queryInterface.bulkInsert('users', [
      {
        roleId: 1,
        firstName: 'Super',
        lastName: 'Admin',
        email: 'admin@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 2,
        firstName: 'Alejandro',
        lastName: 'Dueño',
        email: 'walejandroh95@gmail.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 3,
        firstName: 'Supervisor',
        lastName: 'Supervisor',
        email: 'supervisor@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 4,
        firstName: 'Agent',
        lastName: 'Agent',
        email: 'agent@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 5,
        firstName: 'Developer Sr',
        lastName: 'Developer Sr',
        email: 'developer_sr@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 6,
        firstName: 'Developer Jr',
        lastName: 'Developer Jr',
        email: 'developer_jr@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 7,
        firstName: 'QA',
        lastName: 'QA',
        email: 'qa@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 8,
        firstName: 'Designer',
        lastName: 'Designer',
        email: 'designer@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 9,
        firstName: 'Project Manager',
        lastName: 'Project Manager',
        email: 'project_manager@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 10,
        firstName: 'DBA',
        lastName: 'DBA',
        email: 'dba@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 11,
        firstName: 'DevOps',
        lastName: 'DevOps',
        email: 'devops@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 12,
        firstName: 'Marketing',
        lastName: 'Marketing',
        email: 'marketing@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 13,
        firstName: 'Sales',
        lastName: 'Sales',
        email: 'sales@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 14,
        firstName: 'HR',
        lastName: 'HR',
        email: 'hr@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 15,
        firstName: 'Legal',
        lastName: 'Legal',
        email: 'legal@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      },
      {
        roleId: 16,
        firstName: 'Finance',
        lastName: 'Finance',
        email: 'finance@admin.com',
        password: hashedPassword,
        isActive: false,
        avatar: 'default.png',
        createdAt: new Date(),
        updatedAt: new Date()
      }
    ], {});
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.bulkDelete('users', null, {});
    await queryInterface.bulkDelete('roles', null, {});
  }
};