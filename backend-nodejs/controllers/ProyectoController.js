const { Op } = require('sequelize');
const Proyecto = require('../models/Proyecto');
const User = require('../models/user');
const ProyectoUser = require('../models/ProyectoUser');
const Role = require('../models/role');
const logger = require('../src/logger');

exports.getAll = async (req, res) => {
    try {
        const userId = req.user.id;
        const isAdmin = req.user.role === 'Admin'; // Dependiendo de tu lógica de Auth

        const query = isAdmin ? {} : {
            [Op.or]: [
                { encargadoProyecto: userId },
                { '$equipo.id$': userId }
            ]
        };

        const proyectos = await Proyecto.findAll({
            where: query,
            include: [{
                model: User,
                as: 'equipo',
                attributes: ['id'],
                through: { attributes: [] },
                required: false
            }]
        });
        
        // Sanitize the response slightly
        const sanitizedProyectos = proyectos.map(p => {
             const json = p.toJSON();
             delete json.equipo; // No need to flood the list with team data
             return json;
        });

        res.status(200).json(sanitizedProyectos);
    } catch (error) {
        logger.error(`Error al obtener proyectos: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.getById = async (req, res) => {
    try {
        const proyecto = await Proyecto.findByPk(req.params.id);
        if (!proyecto) {
            return res.status(404).json({ error: 'Proyecto no encontrado.' });
        }
        res.status(200).json(proyecto);
    } catch (error) {
        logger.error(`Error al obtener proyecto ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.create = async (req, res) => {
    try {
        const proyecto = await Proyecto.create(req.body);

        const io = req.app.get('socketio');
        if (io && proyecto.encargadoProyecto) {
            io.emit('proyecto_assigned_notification', {
                proyectoId: proyecto.id,
                proyectoNombre: proyecto.nombre,
                agentName: proyecto.encargadoProyecto,
                assignedBy: req.body.assignedBy || 'Sistema'
            });
        }

        logger.info(`Proyecto creado: "${proyecto.nombre}" (ID=${proyecto.id})`);
        res.status(201).json(proyecto);
    } catch (error) {
        logger.error(`Error al crear proyecto: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.update = async (req, res) => {
    try {
        const proyecto = await Proyecto.findByPk(req.params.id);
        if (!proyecto) {
            return res.status(404).json({ error: 'Proyecto no encontrado.' });
        }

        const previousEncargado = proyecto.encargadoProyecto;
        await proyecto.update(req.body);

        const io = req.app.get('socketio');
        if (io && proyecto.encargadoProyecto && proyecto.encargadoProyecto !== previousEncargado) {
            io.emit('proyecto_assigned_notification', {
                proyectoId: proyecto.id,
                proyectoNombre: proyecto.nombre,
                agentName: proyecto.encargadoProyecto,
                assignedBy: req.body.assignedBy || 'Sistema'
            });
        }

        logger.info(`Proyecto actualizado: ID=${proyecto.id}`);
        res.status(200).json(proyecto);
    } catch (error) {
        logger.error(`Error al actualizar proyecto ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.delete = async (req, res) => {
    try {
        const proyecto = await Proyecto.findByPk(req.params.id);
        if (!proyecto) {
            return res.status(404).json({ error: 'Proyecto no encontrado.' });
        }
        await proyecto.destroy();
        logger.info(`Proyecto eliminado: ID=${req.params.id}`);
        res.status(200).json({ message: 'Proyecto eliminado con éxito.' });
    } catch (error) {
        logger.error(`Error al eliminar proyecto ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

// === EQUIPO (TEAM ASSIGNMENTS) ===

exports.getTeam = async (req, res) => {
    try {
        const { id } = req.params;
        const proyecto = await Proyecto.findByPk(id, {
            include: [{
                model: User,
                as: 'equipo',
                attributes: ['id', 'firstName', 'lastName', 'email', 'isActive', 'avatar'],
                through: { attributes: ['rolEnProyecto', 'createdAt'] },
                include: [{ model: Role, as: 'role', attributes: ['name'] }]
            }]
        });

        if (!proyecto) {
            return res.status(404).json({ error: 'Proyecto no encontrado.' });
        }

        const team = proyecto.equipo.map(user => ({
            id: user.id,
            firstName: user.firstName,
            lastName: user.lastName,
            email: user.email,
            avatar: user.avatar,
            isActive: user.isActive,
            role: user.role?.name || 'Vacio',
            rolEnProyecto: user.ProyectoUser?.rolEnProyecto || 'Colaborador',
            assignedAt: user.ProyectoUser?.createdAt
        }));

        res.status(200).json(team);
    } catch (error) {
        logger.error(`Error al obtener equipo de proyecto ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.addTeamMember = async (req, res) => {
    try {
        const { id } = req.params;
        const { userId, rolEnProyecto } = req.body;

        const proyecto = await Proyecto.findByPk(id);
        const user = await User.findByPk(userId);

        if (!proyecto || !user) {
            return res.status(404).json({ error: 'Proyecto o usuario no encontrado.' });
        }

        const [assignment, created] = await ProyectoUser.findOrCreate({
            where: { proyectoId: id, userId },
            defaults: { rolEnProyecto: rolEnProyecto || 'Colaborador' }
        });

        if (!created) {
            await assignment.update({ rolEnProyecto: rolEnProyecto || 'Colaborador' });
        }

        logger.info(`Usuario ID=${userId} asignado al proyecto ID=${id} con rol ${rolEnProyecto || 'Colaborador'}`);
        res.status(200).json({ message: 'Usuario asignado exitosamente.' });
    } catch (error) {
        logger.error(`Error al añadir colaborador a proyecto ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

exports.removeTeamMember = async (req, res) => {
    try {
        const { id, userId } = req.params;
        
        const count = await ProyectoUser.destroy({
            where: { proyectoId: id, userId }
        });

        if (count === 0) {
            return res.status(404).json({ error: 'El usuario especificado no pertenece al equipo de este proyecto.' });
        }

        logger.info(`Usuario ID=${userId} removido del proyecto ID=${id}`);
        res.status(200).json({ message: 'Miembro retirado exitosamente del equipo.' });
    } catch (error) {
        logger.error(`Error al eliminar colaborador del proyecto ID=${req.params.id}: ${error.message}`, { stack: error.stack });
        res.status(500).json({ error: 'Error interno del servidor.' });
    }
};

