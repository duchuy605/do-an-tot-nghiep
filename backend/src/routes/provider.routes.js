const express = require('express');
const providerController = require('../controllers/ProviderController');
const { authenticate, authorize } = require('../middlewares/xac_thuc');

const router = express.Router();

router.get('/profile', authenticate, authorize('PROVIDER'), providerController.getProfile);
router.put('/profile', authenticate, authorize('PROVIDER'), providerController.updateProfile);

router.get('/jobs', authenticate, authorize('PROVIDER'), providerController.getJobs);
router.get('/jobs/:id', authenticate, authorize('PROVIDER'), providerController.getJobDetail);
router.post('/jobs/:id/accept', authenticate, authorize('PROVIDER'), providerController.acceptJob);
router.post('/jobs/:id/reject', authenticate, authorize('PROVIDER'), providerController.rejectJob);
router.post('/jobs/:id/complete', authenticate, authorize('PROVIDER'), providerController.completeJob);

router.post('/wallet/withdraw', authenticate, authorize('PROVIDER'), providerController.withdrawWallet);

module.exports = router;
