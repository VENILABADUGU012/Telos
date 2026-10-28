const express = require('express');
const router = express.Router();
const taskController = require('../controllers/taskController');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/', taskController.getTasksByDate);
router.post('/', taskController.createTask);
router.patch('/:taskId/toggle', taskController.toggleTaskStatus);
router.get('/:taskId', taskController.getTaskDetails);
router.put('/:taskId', taskController.updateTask);
router.delete('/:taskId', taskController.deleteTask);

module.exports = router;
