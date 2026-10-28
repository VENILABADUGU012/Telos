const express = require('express');
const router = express.Router();
const pointsController = require('../controllers/pointsController');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/chest', pointsController.getPointsChest);

module.exports = router;
