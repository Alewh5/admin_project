const express = require('express');
const router = express.Router();
const ticketController = require('../controllers/ticketController');
const { verifyToken } = require('../middlewares/authMiddleware');
const validate = require('../middlewares/validate');
const { createTicketSchema, ticketReplySchema, updateTicketStatusSchema } = require('../middlewares/schemas');

router.post('/', verifyToken, validate(createTicketSchema), ticketController.createTicket);
router.get('/all', verifyToken, ticketController.getAllTickets);
router.get('/room/:roomId', verifyToken, ticketController.getTicketsByRoom);
router.put('/:id/status', verifyToken, validate(updateTicketStatusSchema), ticketController.updateTicketStatus);
router.post('/:id/reply', verifyToken, validate(ticketReplySchema), ticketController.addTicketReply);

module.exports = router;
