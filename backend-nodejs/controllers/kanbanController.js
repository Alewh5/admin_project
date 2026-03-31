const { Op, sequelize: _seq } = require('sequelize');
const sequelize = require('../config/database');
const TaskColumn = require('../models/TaskColumn');
const Task = require('../models/Task');
const TaskAssignee = require('../models/TaskAssignee');
const ProjectDocument = require('../models/ProjectDocument');
const TaskComment = require('../models/TaskComment');
const User = require('../models/user');
const Sprint = require('../models/sprint');
const logger = require('../src/logger');

// === SPRINTS ===
exports.getSprintsByProject = async (req, res) => {
    try {
        const { proyectoId } = req.params;
        const sprints = await Sprint.findAll({
            where: { proyectoId },
            order: [['createdAt', 'ASC']]
        });
        res.status(200).json(sprints);
    } catch (error) {
        logger.error(`Error al obtener sprints del proyecto ${req.params.proyectoId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.createSprint = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { proyectoId } = req.params;
        const { nombre, descripcion, estado, fechaInicio, fechaFin } = req.body;
        
        const sprint = await Sprint.create(
            { proyectoId, nombre, descripcion, estado, fechaInicio, fechaFin },
            { transaction: t }
        );
        
        await t.commit();
        res.status(201).json(sprint);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al crear sprint: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

// === COLUMNS ===
exports.getColumnsByProject = async (req, res) => {
    try {
        const { proyectoId } = req.params;
        const sprintId = req.query.sprintId;
        
        const taskWhere = sprintId ? { sprintId } : {};

        const columns = await TaskColumn.findAll({ 
            where: { proyectoId },
            include: [{
                model: Task,
                as: 'tasks',
                where: taskWhere,
                required: false,
                include: [{
                    model: User,
                    as: 'assignees',
                    through: { attributes: [] }
                }]
            }],
            order: [
                ['orden', 'ASC'],
                [{ model: Task, as: 'tasks' }, 'orden', 'ASC']
            ]
        });
        res.status(200).json(columns);
    } catch (error) {
        logger.error(`Error al obtener columnas del proyecto ${req.params.proyectoId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.createColumn = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { proyectoId } = req.params;
        const { nombre, color, orden } = req.body;
        
        const column = await TaskColumn.create(
            { proyectoId, nombre, color, orden }, 
            { transaction: t }
        );
        
        await t.commit();
        logger.info(`Columna creada: "${column.nombre}" (ID=${column.id}) para el proyecto ${proyectoId}`);
        res.status(201).json(column);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al crear columna: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.updateColumn = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { id } = req.params;
        const column = await TaskColumn.findByPk(id, { transaction: t });
        
        if (!column) {
            await t.rollback();
            return res.status(404).json({ error: 'Columna no encontrada.' });
        }
        
        await column.update(req.body, { transaction: t });
        await t.commit();
        
        logger.info(`Columna actualizada: ID=${id}`);
        res.status(200).json(column);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al actualizar columna ${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

// === TASKS ===
exports.createTask = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { proyectoId, columnId, sprintId, titulo, descripcion, prioridad, fechaVencimiento, orden, assignees } = req.body;
        
        const task = await Task.create({ 
            proyectoId, columnId, sprintId, titulo, descripcion, prioridad, fechaVencimiento, orden 
        }, { transaction: t });
        
        if (assignees && Array.isArray(assignees) && assignees.length > 0) {
            const assigneeData = assignees.map(userId => ({ taskId: task.id, userId }));
            await TaskAssignee.bulkCreate(assigneeData, { transaction: t });
        }
        
        await t.commit();
        
        const taskWithAssignees = await Task.findByPk(task.id, {
            include: [{ model: User, as: 'assignees', through: { attributes: [] } }]
        });
        
        const io = req.app.get('socketio');
        if (io) {
            io.emit('kanban_task_created', taskWithAssignees);
        }
        
        logger.info(`Tarea creada: "${task.titulo}" (ID=${task.id})`);
        res.status(201).json(taskWithAssignees);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al crear tarea: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.updateTask = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { id } = req.params;
        const task = await Task.findByPk(id, { transaction: t });
        
        if (!task) {
            await t.rollback();
            return res.status(404).json({ error: 'Tarea no encontrada.' });
        }
        
        await task.update(req.body, { transaction: t });
        
        if (req.body.assignees && Array.isArray(req.body.assignees)) {
            // Eliminar asignaciones previas no funcionales en bulk si era necesario, pero setAssignees es provisto por sequelize assoc.  
            // Alternativamente destruimos y creamos para mantener el contexto de la transacción
            await TaskAssignee.destroy({ where: { taskId: task.id }, transaction: t });
            if (req.body.assignees.length > 0) {
                const assigneeData = req.body.assignees.map(userId => ({ taskId: task.id, userId }));
                await TaskAssignee.bulkCreate(assigneeData, { transaction: t });
            }
        }
        
        await t.commit();
        
        const updatedTask = await Task.findByPk(task.id, {
            include: [{ model: User, as: 'assignees', through: { attributes: [] } }]
        });
        
        const io = req.app.get('socketio');
        if (io) {
            io.emit('kanban_task_updated', updatedTask);
        }
        
        logger.info(`Tarea actualizada: ID=${id}`);
        res.status(200).json(updatedTask);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al actualizar tarea ${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

// === COMMENTS (Paginated) ===
exports.getTaskComments = async (req, res) => {
    try {
        const { taskId } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;

        const { count, rows } = await TaskComment.findAndCountAll({
            where: { taskId },
            include: [{ model: User, as: 'user', attributes: ['id', 'firstName', 'lastName', 'email'] }],
            order: [['createdAt', 'DESC']],
            limit,
            offset
        });
        
        res.status(200).json({
            totalItems: count,
            totalPages: Math.ceil(count / limit),
            currentPage: page,
            items: rows
        });
    } catch (error) {
        logger.error(`Error al obtener comentarios de tarea ${req.params.taskId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.addComment = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { taskId } = req.params;
        const { userId, contenido } = req.body;
        
        const comment = await TaskComment.create(
            { taskId, userId, contenido }, 
            { transaction: t }
        );
        
        await t.commit();

        const fullComment = await TaskComment.findByPk(comment.id, {
            include: [{ model: User, as: 'user', attributes: ['id', 'firstName', 'lastName'] }]
        });
        
        const io = req.app.get('socketio');
        if (io) {
            io.emit('kanban_task_commented', fullComment);
        }
        
        logger.info(`Comentario agregado a tarea ID=${taskId} por usuario ID=${userId}`);
        res.status(201).json(fullComment);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al agregar comentario: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

// === DOCUMENTS (Paginated) ===
exports.getProjectDocuments = async (req, res) => {
    try {
        const { proyectoId } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 20;
        const offset = (page - 1) * limit;

        const { count, rows } = await ProjectDocument.findAndCountAll({
            where: { proyectoId },
            include: [{ model: Task, as: 'task', attributes: ['id', 'titulo'], required: false }],
            order: [['createdAt', 'DESC']],
            limit,
            offset
        });

        res.status(200).json({
            totalItems: count,
            totalPages: Math.ceil(count / limit),
            currentPage: page,
            items: rows
        });
    } catch (error) {
        logger.error(`Error al obtener documentos del proyecto ${req.params.proyectoId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.uploadDocument = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        if (!req.file) {
            await t.rollback();
            return res.status(400).json({ error: 'No se subió ningún archivo' });
        }
        
        const { proyectoId, taskId } = req.body;
        const nombre = req.file.originalname;
        const ruta = `/uploads/proyectos/${req.file.filename}`;
        const tipo = req.file.mimetype;
        
        const document = await ProjectDocument.create(
            { proyectoId, taskId: taskId || null, nombre, ruta, tipo }, 
            { transaction: t }
        );
        
        await t.commit();
        
        logger.info(`Documento subido: "${nombre}" para el proyecto ${proyectoId}`);
        res.status(201).json(document);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al subir documento: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

// === PROJECT CHAT (Using a hidden Task entity) ===
async function getOrCreateGeneralChat(proyectoId, transaction) {
    let task = await Task.findOne({ where: { proyectoId, titulo: '__CHAT_GENERAL__' }, transaction });
    if (!task) {
        task = await Task.create({ proyectoId, titulo: '__CHAT_GENERAL__', prioridad: 'Media', orden: 0 }, { transaction });
    }
    return task.id;
}

exports.getProjectChat = async (req, res) => {
    try {
        const { proyectoId } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 30;
        const offset = (page - 1) * limit;

        const taskId = await getOrCreateGeneralChat(proyectoId);

        const { count, rows } = await TaskComment.findAndCountAll({
            where: { taskId },
            include: [{ model: User, as: 'user', attributes: ['id', 'firstName', 'lastName'] }],
            order: [['createdAt', 'DESC']],
            limit,
            offset
        });
        
        res.status(200).json({ totalItems: count, totalPages: Math.ceil(count / limit), currentPage: page, items: rows });
    } catch (error) {
        logger.error(`Error al obtener chat de proyecto: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.addProjectChat = async (req, res) => {
    const t = await sequelize.transaction();
    try {
        const { proyectoId } = req.params;
        const { userId, contenido } = req.body;
        
        const taskId = await getOrCreateGeneralChat(proyectoId, t);
        const comment = await TaskComment.create({ taskId, userId, contenido }, { transaction: t });
        
        await t.commit();

        const fullComment = await TaskComment.findByPk(comment.id, {
            include: [{ model: User, as: 'user', attributes: ['id', 'firstName', 'lastName'] }]
        });
        
        const io = req.app.get('socketio');
        if (io) io.emit(`kanban_project_${proyectoId}_chat`, fullComment);
        
        res.status(201).json(fullComment);
    } catch (error) {
        await t.rollback();
        logger.error(`Error al enviar mensaje de proyecto: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

// === METRICS ===
exports.getProjectMetrics = async (req, res) => {
    try {
        const { proyectoId } = req.params;
        
        const totalTasks = await Task.count({ where: { proyectoId } });
        
        const completedTasks = await Task.count({ 
            where: { proyectoId, prioridad: 'Baja' } 
        });
        
        const overdueTasks = await Task.count({ 
            where: { 
                proyectoId, 
                fechaVencimiento: { [Op.lt]: new Date() } 
            }  
        });

        const projectTasks = await Task.findAll({ where: { proyectoId }, attributes: ['id'] });
        const taskIds = projectTasks.map(t => t.id);
        const totalComments = taskIds.length > 0 
            ? await TaskComment.count({ where: { taskId: { [Op.in]: taskIds } } })
            : 0;

        res.status(200).json({ totalTasks, completedTasks, overdueTasks, totalComments });
    } catch (error) {
        logger.error(`Error al obtener metricas del proyecto ${req.params.proyectoId}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};
