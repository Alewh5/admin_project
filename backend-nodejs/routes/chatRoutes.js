const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const multer = require('multer');
const path = require('path');
const { verifyToken } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { createRoomSchema } = require('../middlewares/schemas');

const MIME_PERMITIDOS = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
const TAMANO_MAXIMO = 5 * 1024 * 1024;

const storage = multer.diskStorage({
    destination: function (req, file, cb) {
        cb(null, 'public/uploads/')
    },
    filename: function (req, file, cb) {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});

const fileFilter = (req, file, cb) => {
    if (MIME_PERMITIDOS.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error(`Tipo de archivo no permitido: ${file.mimetype}. Solo se aceptan imágenes (JPEG, PNG, GIF, WebP).`), false);
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: { fileSize: TAMANO_MAXIMO }
});

const handleUpload = (req, res, next) => {
    upload.single('file')(req, res, (err) => {
        if (!err) return next();
        if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ error: 'El archivo supera el tamaño máximo permitido de 5 MB.' });
        }
        return res.status(400).json({ error: err.message || 'Error al procesar el archivo.' });
    });
};

router.post('/room', validate(createRoomSchema), chatController.createRoom);
router.get('/history/:roomId', chatController.getHistory);
router.post('/upload', handleUpload, chatController.uploadFile);

router.get('/rooms', verifyToken, chatController.getActiveRooms);
router.get('/history-rooms', verifyToken, chatController.getHistoricalRooms);
router.put('/room/:roomId/assign', verifyToken, chatController.assignAgent);
router.post('/room/:roomId/rate', chatController.rateRoom);

module.exports = router;