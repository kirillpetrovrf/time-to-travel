/**
 * 🚖 Taxi Tracking Backend API
 * ============================
 * 
 * Node.js + Express + Redis сервер для отслеживания такси
 * 
 * Установка:
 * npm install express redis cors body-parser
 * 
 * Запуск:
 * node server.js
 * 
 * API будет доступен на http://localhost:3000
 */

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const redis = require('redis');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Redis client
const redisClient = redis.createClient({
  socket: {
    host: 'localhost',
    port: 6379,
  }
});

redisClient.on('error', (err) => console.error('❌ Redis Client Error', err));
redisClient.on('connect', () => console.log('✅ Connected to Redis'));

// Connect to Redis
(async () => {
  await redisClient.connect();
})();

// ============================================================================
// API ENDPOINTS
// ============================================================================

/**
 * POST /api/trips
 * Создать новую поездку
 */
app.post('/api/trips', async (req, res) => {
  try {
    const tripId = 'trip_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
    const tripData = {
      tripId,
      from: req.body.from,
      to: req.body.to,
      driverId: req.body.driverId,
      customerId: req.body.customerId,
      status: 'created',
      createdAt: new Date().toISOString(),
    };
    
    // Сохраняем на 1 час (3600 секунд)
    await redisClient.setEx(`trip:${tripId}`, 3600, JSON.stringify(tripData));
    
    console.log(`✅ Trip created: ${tripId}`);
    console.log(`   From: ${tripData.from.latitude}, ${tripData.from.longitude}`);
    console.log(`   To: ${tripData.to.latitude}, ${tripData.to.longitude}`);
    
    res.json({ tripId });
  } catch (error) {
    console.error('❌ Error creating trip:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PATCH /api/trips/:tripId/start
 * Начать поездку (изменить статус на in_progress)
 */
app.patch('/api/trips/:tripId/start', async (req, res) => {
  try {
    const { tripId } = req.params;
    const tripDataStr = await redisClient.get(`trip:${tripId}`);
    
    if (!tripDataStr) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    
    const tripData = JSON.parse(tripDataStr);
    tripData.status = 'in_progress';
    tripData.startedAt = new Date().toISOString();
    
    await redisClient.setEx(`trip:${tripId}`, 3600, JSON.stringify(tripData));
    
    console.log(`🚕 Trip started: ${tripId}`);
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Error starting trip:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/trips/:tripId/location
 * Отправить GPS координаты водителя
 */
app.post('/api/trips/:tripId/location', async (req, res) => {
  try {
    const { tripId } = req.params;
    const locationData = {
      latitude: req.body.latitude,
      longitude: req.body.longitude,
      bearing: req.body.bearing || 0,
      speed: req.body.speed || 0,
      accuracy: req.body.accuracy || 0,
      timestamp: new Date().toISOString(),
    };
    
    // Храним локацию 5 минут (300 секунд)
    await redisClient.setEx(
      `trip:${tripId}:location`,
      300,
      JSON.stringify(locationData)
    );
    
    console.log(`📍 Location updated for ${tripId}:`);
    console.log(`   Lat: ${locationData.latitude.toFixed(6)}`);
    console.log(`   Lng: ${locationData.longitude.toFixed(6)}`);
    console.log(`   Speed: ${locationData.speed.toFixed(1)} m/s`);
    console.log(`   Bearing: ${locationData.bearing.toFixed(1)}°`);
    
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Error saving location:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/trips/:tripId/location
 * Получить текущую локацию такси (для клиента)
 */
app.get('/api/trips/:tripId/location', async (req, res) => {
  try {
    const { tripId } = req.params;
    const locationDataStr = await redisClient.get(`trip:${tripId}:location`);
    
    if (!locationDataStr) {
      return res.status(404).json({ error: 'Location not found' });
    }
    
    const locationData = JSON.parse(locationDataStr);
    console.log(`📥 Location requested for ${tripId}`);
    
    res.json(locationData);
  } catch (error) {
    console.error('❌ Error fetching location:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/trips/:tripId
 * Получить детали поездки
 */
app.get('/api/trips/:tripId', async (req, res) => {
  try {
    const { tripId } = req.params;
    const tripDataStr = await redisClient.get(`trip:${tripId}`);
    
    if (!tripDataStr) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    
    const tripData = JSON.parse(tripDataStr);
    res.json(tripData);
  } catch (error) {
    console.error('❌ Error fetching trip:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PATCH /api/trips/:tripId/complete
 * Завершить поездку
 */
app.patch('/api/trips/:tripId/complete', async (req, res) => {
  try {
    const { tripId } = req.params;
    const tripDataStr = await redisClient.get(`trip:${tripId}`);
    
    if (!tripDataStr) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    
    const tripData = JSON.parse(tripDataStr);
    tripData.status = 'completed';
    tripData.completedAt = new Date().toISOString();
    
    await redisClient.setEx(`trip:${tripId}`, 3600, JSON.stringify(tripData));
    
    console.log(`✅ Trip completed: ${tripId}`);
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Error completing trip:', error);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PATCH /api/trips/:tripId/cancel
 * Отменить поездку
 */
app.patch('/api/trips/:tripId/cancel', async (req, res) => {
  try {
    const { tripId } = req.params;
    const { reason } = req.body;
    const tripDataStr = await redisClient.get(`trip:${tripId}`);
    
    if (!tripDataStr) {
      return res.status(404).json({ error: 'Trip not found' });
    }
    
    const tripData = JSON.parse(tripDataStr);
    tripData.status = 'cancelled';
    tripData.reason = reason;
    tripData.cancelledAt = new Date().toISOString();
    
    await redisClient.setEx(`trip:${tripId}`, 3600, JSON.stringify(tripData));
    
    console.log(`❌ Trip cancelled: ${tripId} (${reason})`);
    res.json({ success: true });
  } catch (error) {
    console.error('❌ Error cancelling trip:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// SERVER START
// ============================================================================

app.listen(PORT, () => {
  console.log('');
  console.log('🚖 ============================================');
  console.log('🚖  Taxi Tracking Backend API');
  console.log('🚖 ============================================');
  console.log(`🌐 Server running on http://localhost:${PORT}`);
  console.log('');
  console.log('📡 Available endpoints:');
  console.log(`   POST   http://localhost:${PORT}/api/trips`);
  console.log(`   PATCH  http://localhost:${PORT}/api/trips/:id/start`);
  console.log(`   POST   http://localhost:${PORT}/api/trips/:id/location`);
  console.log(`   GET    http://localhost:${PORT}/api/trips/:id/location`);
  console.log(`   GET    http://localhost:${PORT}/api/trips/:id`);
  console.log(`   PATCH  http://localhost:${PORT}/api/trips/:id/complete`);
  console.log(`   PATCH  http://localhost:${PORT}/api/trips/:id/cancel`);
  console.log('');
  console.log('🔧 For Android Emulator use: http://10.0.2.2:3000/api');
  console.log('🔧 For iOS Simulator use: http://localhost:3000/api');
  console.log('🔧 For Real Device use: http://YOUR_LOCAL_IP:3000/api');
  console.log('');
  console.log('⚡ Redis должен быть запущен на localhost:6379');
  console.log('   Установка: brew install redis (macOS)');
  console.log('   Запуск: redis-server');
  console.log('');
  console.log('✅ Ready to accept requests!');
  console.log('🚖 ============================================');
  console.log('');
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('🛑 SIGTERM received, shutting down...');
  await redisClient.quit();
  process.exit(0);
});
