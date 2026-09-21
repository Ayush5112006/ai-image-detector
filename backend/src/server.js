import { app, connectDb } from './app.js';
import { logger } from './utils/logger.js';

const port = process.env.PORT || 4000;

connectDb()
  .then(() => {
    app.listen(port, () => {
      logger.info('server started', { port, nodeEnv: process.env.NODE_ENV || 'development' });
      console.log(`ChitraVision API listening on http://localhost:${port}`);
    });
  })
  .catch((err) => {
    console.error('MongoDB connection failed:', err.message);
    process.exit(1);
  });