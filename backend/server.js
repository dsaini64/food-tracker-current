const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const multer = require('multer');
const sharp = require('sharp');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const chatGPTService = require('./services/chatgptService');
const nutritionService = require('./services/nutritionService');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000', 'http://10.20.10.206:3000'],
  credentials: true
};
app.use(cors(corsOptions));

// Rate limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 minutes
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// Configure multer for image uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: (parseInt(process.env.MAX_IMAGE_SIZE_MB) || 10) * 1024 * 1024 // 10MB default
  },
  fileFilter: (req, file, cb) => {
    // Accept all image files for now to avoid iOS upload issues
    const allowedMimeTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'application/octet-stream'];
    
    if (allowedMimeTypes.includes(file.mimetype) || file.mimetype.startsWith('image/')) {
      console.log(`File accepted: ${file.originalname}, mimetype: ${file.mimetype}`);
      cb(null, true);
    } else {
      console.log(`File rejected: ${file.originalname}, mimetype: ${file.mimetype}`);
      cb(new Error(`Invalid file type. Allowed types: image files`), false);
    }
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Test endpoint for debugging
app.get('/test', (req, res) => {
  res.json({ 
    message: 'Backend is working!',
    timestamp: new Date().toISOString(),
    ip: req.ip,
    userAgent: req.get('User-Agent')
  });
});

// Analyze food image endpoint
app.post('/api/analyze-food', upload.single('image'), async (req, res) => {
  try {
    console.log('🍎 Food analysis request received');
    console.log('📱 Request headers:', req.headers);
    console.log('📱 Request body keys:', Object.keys(req.body || {}));
    console.log('📱 File info:', req.file ? {
      fieldname: req.file.fieldname,
      originalname: req.file.originalname,
      mimetype: req.file.mimetype,
      size: req.file.size
    } : 'No file');
    
    if (!req.file) {
      console.log('❌ No image file provided');
      return res.status(400).json({ 
        error: 'No image provided',
        code: 'NO_IMAGE'
      });
    }

    // Process image with Sharp (resize, optimize)
    const processedImage = await sharp(req.file.buffer)
      .resize(1024, 1024, { 
        fit: 'inside',
        withoutEnlargement: true 
      })
      .jpeg({ quality: 85 })
      .toBuffer();

    // Convert to base64 for ChatGPT Vision
    const base64Image = processedImage.toString('base64');
    
    // Analyze with ChatGPT Vision
    console.log('🤖 Calling ChatGPT Vision API...');
    const chatGPTResponse = await chatGPTService.analyzeFoodImage(base64Image);
    console.log('🤖 ChatGPT response:', JSON.stringify(chatGPTResponse, null, 2));
    
    // Enhance with nutrition data
    console.log('🥗 Enhancing with nutrition data...');
    const enhancedAnalysis = await nutritionService.enhanceWithNutritionData(chatGPTResponse);
    console.log('🥗 Enhanced analysis:', JSON.stringify(enhancedAnalysis, null, 2));
    
    // Generate unique analysis ID
    const analysisId = uuidv4();
    
    res.json({
      success: true,
      analysisId,
      timestamp: new Date().toISOString(),
      analysis: enhancedAnalysis
    });

  } catch (error) {
    console.error('Error analyzing food:', error);
    
    // Handle specific error types
    if (error.message.includes('Invalid file type')) {
      return res.status(400).json({
        error: 'Invalid file type',
        code: 'INVALID_FILE_TYPE',
        message: error.message
      });
    }
    
    if (error.message.includes('File too large')) {
      return res.status(400).json({
        error: 'File too large',
        code: 'FILE_TOO_LARGE',
        message: `Maximum file size is ${process.env.MAX_IMAGE_SIZE_MB || 10}MB`
      });
    }
    
    // Generic error response
    res.status(500).json({
      error: 'Internal server error',
      code: 'ANALYSIS_FAILED',
      message: 'Failed to analyze food image'
    });
  }
});

// Get nutrition suggestions endpoint
app.post('/api/nutrition-suggestions', async (req, res) => {
  try {
    const { foodItems, userGoals } = req.body;
    
    if (!foodItems || !Array.isArray(foodItems)) {
      return res.status(400).json({
        error: 'Invalid food items provided',
        code: 'INVALID_FOOD_ITEMS'
      });
    }
    
    const suggestions = await nutritionService.generateSuggestions(foodItems, userGoals);
    
    res.json({
      success: true,
      suggestions
    });
    
  } catch (error) {
    console.error('Error generating suggestions:', error);
    res.status(500).json({
      error: 'Failed to generate suggestions',
      code: 'SUGGESTIONS_FAILED'
    });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  console.error('Unhandled error:', error);
  
  if (error instanceof multer.MulterError) {
    if (error.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({
        error: 'File too large',
        code: 'FILE_TOO_LARGE'
      });
    }
  }
  
  res.status(500).json({
    error: 'Internal server error',
    code: 'UNKNOWN_ERROR'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    code: 'NOT_FOUND'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🍎 Food Tracker Backend running on port ${PORT}`);
  console.log(`📊 Health check: http://localhost:${PORT}/health`);
  console.log(`🔍 Food analysis: http://localhost:${PORT}/api/analyze-food`);
});

module.exports = app;

