const express = require('express');
const router = express.Router();
const postController = require('../controllers/postController');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/profile/:userId?', postController.getUserProfile);
router.post('/', postController.createPost);
router.post('/:postId/like', postController.toggleLike);
router.post('/:postId/comments', postController.addComment);
router.delete('/:postId', postController.deletePost);

module.exports = router;
