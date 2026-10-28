const express = require('express');
const router = express.Router();
const messageController = require('../controllers/messageController');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/conversations', messageController.getConversations);
router.post('/conversations/direct', messageController.getOrCreateDirectConversation);
router.post('/conversations/group', messageController.createGroupConversation);
router.get('/conversations/:conversationId/messages', messageController.getMessages);
router.post('/conversations/:conversationId/messages', messageController.sendMessage);
router.post('/messages/:messageId/vote', messageController.votePoll);
router.post('/conversations/:conversationId/tasks', messageController.createGroupTask);
router.get('/tasks/:taskId/monitoring', messageController.getGroupTaskMonitoring);

module.exports = router;
