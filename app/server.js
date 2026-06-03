const express = require('express');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

// Health checks
app.get('/health/live', (req, res) => res.json({ status: 'ok' }));
app.get('/health/ready', (req, res) => res.json({ status: 'ok' }));

// Hello world endpoint
app.post('/api/v1/hello', (req, res) => {
  res.json({ message: 'Hello, World!', payload: req.body });
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down...');
  server.close(() => process.exit(0));
});

const server = app.listen(PORT, () => {
  console.log(`API listening on port ${PORT}`);
});
