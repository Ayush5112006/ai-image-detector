import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';

import authRoutes from './routes/auth.routes.js';
import detectionRoutes from './routes/detection.routes.js';
import userRoutes from './routes/user.routes.js';

const app = express();

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/api/health', (req, res) => res.json({ status: 'ok' }));
app.use('/api/auth', authRoutes);
app.use('/api/detections', detectionRoutes);
app.use('/api/user', userRoutes);

app.use((req, res) => res.status(404).json({ message: 'Not found' }));

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: 'Server error. Please try again later.' });
});

const port = process.env.PORT || 4000;

mongoose
  .connect(process.env.MONGODB_URI)
  .then(() => {
    app.listen(port, () => {
      console.log(`ChitraVision API listening on http://localhost:${port}`);
    });
  })
  .catch((err) => {
    console.error('MongoDB connection failed:', err.message);
    process.exit(1);
  });