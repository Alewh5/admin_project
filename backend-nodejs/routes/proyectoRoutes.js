const express = require('express');
const router = express.Router();
const proyectoController = require('../controllers/ProyectoController');
const { verifyToken } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { createProyectoSchema, updateProyectoSchema } = require('../middlewares/schemas');

router.get('/', verifyToken, proyectoController.getAll);
router.get('/:id', verifyToken, proyectoController.getById);
router.post('/', verifyToken, validate(createProyectoSchema), proyectoController.create);
router.put('/:id', verifyToken, validate(updateProyectoSchema), proyectoController.update);
router.delete('/:id', verifyToken, proyectoController.delete);

router.get('/:id/equipo', verifyToken, proyectoController.getTeam);
router.post('/:id/equipo', verifyToken, proyectoController.addTeamMember);
router.delete('/:id/equipo/:userId', verifyToken, proyectoController.removeTeamMember);

module.exports = router;
