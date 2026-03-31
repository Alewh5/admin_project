const express = require('express');
const router = express.Router();
const reportsController = require('../controllers/reportsController');
const { verifyToken } = require('../middlewares/authMiddleware');

router.get('/summary', verifyToken, reportsController.getSummary);
router.get('/ranking', verifyToken, reportsController.getAgentRanking);

module.exports = router;