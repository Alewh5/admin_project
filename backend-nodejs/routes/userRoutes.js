const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken, checkRole } = require('../middlewares/authMiddleware');

const uploadAvatar = require('../middlewares/uploadAvatarMiddleware');

router.get('/', verifyToken, checkRole(['ROOT', 'OWNER']), userController.getUsers);
router.get('/invitable', verifyToken, userController.getInvitableUsers);
router.post('/', verifyToken, checkRole(['ROOT', 'OWNER']), userController.createUser);
router.put('/:id', verifyToken, checkRole(['ROOT', 'OWNER']), userController.updateUser);
router.delete('/:id', verifyToken, checkRole(['ROOT', 'OWNER']), userController.deleteUser);
router.patch('/:id/status', verifyToken, checkRole(['ROOT', 'OWNER']), userController.toggleUserStatus);
router.post('/:id/avatar', verifyToken, uploadAvatar.single('avatar'), userController.uploadAvatar);

module.exports = router;