'use strict';

module.exports = {
  async up (queryInterface, Sequelize) {
    const proyectos = await queryInterface.sequelize.query(
      `SELECT id from proyectos LIMIT 1;`
    );
    
    // Si hay proyectos, tomar el primero para crearle sprints de prueba
    if (proyectos[0] && proyectos[0].length > 0) {
      const pId = proyectos[0][0].id;
      
      await queryInterface.bulkInsert('sprints', [
        {
          proyectoId: pId,
          nombre: 'Sprint 1 - Base de Datos',
          descripcion: 'Diseño e implementación de esquemas iniciales',
          estado: 2, // Completado
          fechaInicio: new Date(),
          fechaFin: new Date(),
          createdAt: new Date(),
          updatedAt: new Date()
        },
        {
          proyectoId: pId,
          nombre: 'Sprint 2 - Backend API',
          descripcion: 'Construcción y segurización de Controladores',
          estado: 1, // Activo
          fechaInicio: new Date(),
          fechaFin: new Date(new Date().setDate(new Date().getDate() + 7)),
          createdAt: new Date(),
          updatedAt: new Date()
        },
        {
          proyectoId: pId,
          nombre: 'Sprint 3 - Flutter Panel',
          descripcion: 'Generar vistas híbridas',
          estado: 0, // Planeado
          fechaInicio: null,
          fechaFin: null,
          createdAt: new Date(),
          updatedAt: new Date()
        }
      ]);
    }
  },

  async down (queryInterface, Sequelize) {
    await queryInterface.bulkDelete('sprints', null, {});
  }
};
