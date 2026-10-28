const express = require('express');
const router = express.Router();
const searchController = require('../controllers/searchController');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/', searchController.globalSearch);

module.exports = router;
