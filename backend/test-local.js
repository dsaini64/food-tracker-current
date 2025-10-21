// Test script to verify backend is working locally
const express = require('express');
const cors = require('cors');
const multer = require('multer');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3000;

// Basic CORS for local testing
app.use(cors({
  origin: '*', // Allow all origins for testing
  credentials: true
}));

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configure multer for image uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
    message: 'Local backend is running!'
  });
});

// Test endpoint
app.get('/test', (req, res) => {
  res.json({ 
    message: 'Backend is working!',
    timestamp: new Date().toISOString(),
    ip: req.ip
  });
});

// Mock analyze endpoint for testing
app.post('/api/analyze-food', upload.single('image'), async (req, res) => {
  try {
    console.log('🍎 Mock food analysis request received');
    
    if (!req.file) {
      return res.status(400).json({ 
        error: 'No image provided',
        code: 'NO_IMAGE'
      });
    }

    // Mock response for testing
    const mockAnalysis = {
      foods: [{
        id: `food_${Date.now()}_0`,
        name: "Test Food Item",
        calories: 250,
        protein: 15,
        carbs: 30,
        fat: 8,
        fiber: 3,
        serving_size: "1 serving",
        confidence: 0.85,
        cooking_method: "Grilled",
        health_notes: "Good source of protein"
      }],
      overallConfidence: 0.85,
      imageDescription: "A test food item for development",
      suggestions: ["This is a test response"],
      totals: {
        calories: 250,
        protein: 15,
        carbs: 30,
        fat: 8,
        fiber: 3
      },
      insights: ["Test insight"],
      timestamp: new Date().toISOString()
    };
    
    res.json({
      success: true,
      analysisId: uuidv4(),
      timestamp: new Date().toISOString(),
      analysis: mockAnalysis
    });

  } catch (error) {
    console.error('Error in mock analysis:', error);
    res.status(500).json({
      error: 'Internal server error',
      code: 'ANALYSIS_FAILED'
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🍎 Local Test Backend running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔍 Test analysis: http://localhost:${PORT}/api/analyze-food`);
  console.log(`\n🚀 To test with your iOS app, update FoodAnalysisService.swift:`);
  console.log(`   private let baseURL = "http://localhost:${PORT}"`);
});
