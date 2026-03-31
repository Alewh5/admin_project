require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const path = require('path');
const logger = require('./src/logger');
const { generalLimiter, loginLimiter } = require('./middlewares/rateLimiter');
const chatRoutes = require('./routes/chatRoutes');
const socketHandler = require('./sockets/socketHandler');
const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const ticketRoutes = require('./routes/ticketRoutes');
const proyectoRoutes = require('./routes/proyectoRoutes');
const reportsRoutes = require('./routes/reportsRoutes');
const kanbanRoutes = require('./routes/kanbanRoutes');

const app = express();
app.use(cors());
app.use(express.json());

// ── Health check (no pasa por rate limiter para no bloquear monitoreo) ───────
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        timestamp: new Date().toISOString(),
        uptime: Math.floor(process.uptime()),
        environment: process.env.NODE_ENV || 'development'
    });
});

// Rate limiting general para toda la API
app.use('/api/', generalLimiter);
// Rate limiting estricto solo para el login
app.use('/api/auth/login', loginLimiter);

app.use('/uploads', express.static(path.join(__dirname, 'public/uploads')));
app.use('/api/chat', chatRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/tickets', ticketRoutes);
app.use('/api/proyectos', proyectoRoutes);
app.use('/api/kanban', kanbanRoutes);
app.use('/api/reports', reportsRoutes);


// Manejo global de errores no capturados
app.use((err, req, res, next) => {
    logger.error(`Error no controlado: ${err.message}`, { stack: err.stack });
    res.status(500).json({ error: 'Error interno del servidor.' });
});

const server = http.createServer(app);

const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

app.set('socketio', io);
socketHandler(io);

const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
    logger.info(`Servidor iniciado en el puerto ${PORT}`);
});