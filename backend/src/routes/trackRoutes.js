const express = require('express');
const router = express.Router();
const trackController = require('../controllers/trackController');
const auth = require('../middleware/auth');

router.use(auth);

router.get('/', trackController.getUserTracks);
router.post('/', trackController.createTrack);
router.get('/public', trackController.getPublicTracks);
router.get('/templates', trackController.getTemplates);
router.post('/templates/:templateId/apply', trackController.applyTemplate);
router.get('/:trackId', trackController.getTrackDetails);
router.put('/:trackId', trackController.updateTrack);
router.post('/:trackId/join', trackController.joinTrack);

module.exports = router;
