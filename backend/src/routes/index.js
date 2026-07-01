const express = require('express');
const authRoutes = require('./auth.routes');
const customerRoutes = require('./customer.routes');
const providerRoutes = require('./provider.routes');
const adminRoutes = require('./admin.routes');
const notificationRoutes = require('./notification.routes');

const mainRouter = express.Router();

mainRouter.use('/auth', authRoutes);
mainRouter.use('/', customerRoutes); // Directly mounts services, bookings, wallet, reviews, complaints
mainRouter.use('/provider', providerRoutes);
mainRouter.use('/admin', adminRoutes);
mainRouter.use('/notifications', notificationRoutes);

module.exports = mainRouter;
