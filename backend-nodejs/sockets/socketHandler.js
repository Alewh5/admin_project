const Room = require('../models/Room');
const Message = require('../models/Message');
const logger = require('../src/logger');

module.exports = (io) => {
    io.on('connection', (socket) => {
        logger.debug(`Socket conectado: ${socket.id}`);

        socket.on('join_room', async (data) => {
            const { roomId, userId, role } = data;
            socket.join(roomId);
            logger.info(`[Socket] ${role} "${userId}" se unió a la sala ${roomId}`);

            try {
                if (role === 'agent') {
                    const room = await Room.findByPk(roomId);
                    if (room) {
                        await room.update({
                            agentId: room.agentId || userId,
                            agentName: room.agentName || userId,
                            status: 'in_progress'
                        });
                        io.emit('room_list_updated');
                    }
                    io.to(roomId).emit('user_joined', {
                        userId,
                        role,
                        timestamp: new Date().toISOString()
                    });
                } else if (role === 'visitor') {
                    await Room.findOrCreate({
                        where: { id: roomId },
                        defaults: { status: 'open' }
                    });
                    io.emit('new_room_created');
                    io.emit('room_list_updated');
                    io.to(roomId).emit('user_joined', {
                        userId,
                        role,
                        timestamp: new Date().toISOString()
                    });
                }
            } catch (error) {
                logger.error(`[Socket] Error al unirse a la sala ${roomId}: ${error.message}`, { stack: error.stack });
            }
        });

        socket.on('send_message', async (data) => {
            const { roomId, message, senderId, role, type = 'text', fileUrl = null } = data;

            try {
                const nuevoMensaje = await Message.create({
                    roomId, senderId, role, message, type, fileUrl
                });

                io.to(roomId).emit('receive_message', nuevoMensaje);

                if (role === 'visitor') {
                    io.emit('global_new_message', nuevoMensaje);
                }

                logger.debug(`[Socket] Mensaje enviado en sala ${roomId} por ${senderId} (${role})`);
            } catch (error) {
                logger.error(`[Socket] Error al guardar mensaje en sala ${roomId}: ${error.message}`, { stack: error.stack });
            }
        });

        socket.on('typing', (data) => {
            const { roomId, isTyping, role, previewText } = data;
            socket.to(roomId).emit('user_typing', { roomId, isTyping, role, previewText });
        });

        socket.on('room_assigned', (data) => {
            logger.info(`[Socket] Sala asignada: ${JSON.stringify(data)}`);
            io.emit('room_assigned_notification', data);
            io.emit('room_list_updated');
        });

        socket.on('close_room', async (data) => {
            const { roomId } = data;
            try {
                await Room.update({ status: 'closed' }, { where: { id: roomId } });
                io.to(roomId).emit('room_closed', { roomId });
                io.emit('room_list_updated');
                logger.info(`[Socket] Sala cerrada: ${roomId}`);
            } catch (error) {
                logger.error(`[Socket] Error al cerrar la sala ${roomId}: ${error.message}`, { stack: error.stack });
            }
        });

        socket.on('disconnect', () => {
            logger.debug(`[Socket] Socket desconectado: ${socket.id}`);
        });
    });
};