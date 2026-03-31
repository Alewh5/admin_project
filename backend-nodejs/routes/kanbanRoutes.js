const express = require('express');
const router = express.Router();
const kanbanController = require('../controllers/kanbanController');
const multer = require('multer');
const path = require('path');

// Configuración de multer para subir documentos de proyecto
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, 'public/uploads/');
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, 'proyecto-' + uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({ storage });

// Sprints
router.get('/proyectos/:proyectoId/sprints', kanbanController.getSprintsByProject);
router.post('/proyectos/:proyectoId/sprints', kanbanController.createSprint);

// Columnas
router.get('/proyectos/:proyectoId/columns', kanbanController.getColumnsByProject);
router.post('/proyectos/:proyectoId/columns', kanbanController.createColumn);
router.put('/columns/:id', kanbanController.updateColumn);

// Tareas
router.post('/tasks', kanbanController.createTask);
router.put('/tasks/:id', kanbanController.updateTask);

// Comentarios
router.get('/tasks/:taskId/comments', kanbanController.getTaskComments);
router.post('/tasks/:taskId/comments', kanbanController.addComment);

// Documentos
router.get('/proyectos/:proyectoId/documents', kanbanController.getProjectDocuments);
router.post('/documents/upload', upload.single('documento'), kanbanController.uploadDocument);

// Chat Proyecto
router.get('/proyectos/:proyectoId/chat', kanbanController.getProjectChat);
router.post('/proyectos/:proyectoId/chat', kanbanController.addProjectChat);

// Rendimiento
router.get('/proyectos/:proyectoId/rendimiento', kanbanController.getProjectMetrics);

module.exports = router;
