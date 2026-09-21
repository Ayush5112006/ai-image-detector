import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';

import authRoutes from './routes/auth.routes.js';
import detectionRoutes from './routes/detection.routes.js';
import userRoutes from './routes/user.routes.js';
import adminRoutes from './routes/admin.routes.js';
import { requestContext } from './middleware/requestContext.js';
import { notFoundHandler, errorHandler } from './middleware/errorHandler.js';
import { logger } from './utils/logger.js';

export const app = express();

app.use(cors());
app.use(express.json({ limit: '2mb' }));
app.use(requestContext);

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'chitravision-backend',
    mlUrlConfigured: Boolean(process.env.FASTAPI_URL),
    nodeEnv: process.env.NODE_ENV || 'development',
  });
});
app.use('/api/auth', authRoutes);
app.use('/api/detections', detectionRoutes);
app.use('/api/user', userRoutes);
app.use('/api/admin', adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

export async function connectDb(uri = process.env.MONGODB_URI) {
  await mongoose.connect(uri);
  logger.info('MongoDB connected');
}

export default app;