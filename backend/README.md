# Food Tracker Backend

A Node.js backend service that integrates with ChatGPT Vision API for food recognition and nutrition analysis.

## Features

- 🍎 **ChatGPT Vision Integration** - Advanced food recognition using GPT-4V
- 📊 **Nutrition Analysis** - Detailed macro and micronutrient breakdown
- 🎯 **Smart Suggestions** - Personalized nutrition recommendations
- 🖼️ **Image Processing** - Automatic image optimization and validation
- 🚀 **Rate Limiting** - Built-in protection against abuse
- 🔒 **Security** - Helmet.js security headers and CORS protection

## Setup

### Prerequisites

- Node.js 18+ 
- OpenAI API key
- npm or yarn

### Installation

1. **Clone and navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up environment variables:**
   ```bash
   cp env.example .env
   ```
   
   Edit `.env` and add your OpenAI API key:
   ```
   OPENAI_API_KEY=your_openai_api_key_here
   ```

4. **Start the server:**
   ```bash
   # Development mode with auto-restart
   npm run dev
   
   # Production mode
   npm start
   ```

The server will start on `http://localhost:3000`

## API Endpoints

### Health Check
```
GET /health
```
Returns server status and version info.

### Analyze Food Image
```
POST /api/analyze-food
Content-Type: multipart/form-data

Body: image file (JPG, PNG, WebP)
```

**Response:**
```json
{
  "success": true,
  "analysisId": "uuid",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "analysis": {
    "foods": [
      {
        "name": "Grilled Chicken Breast",
        "calories": 165,
        "protein": 31,
        "carbs": 0,
        "fat": 3.6,
        "fiber": 0,
        "serving_size": "100g",
        "confidence": 0.92,
        "cooking_method": "grilled",
        "health_notes": "High protein, low fat",
        "verified": true
      }
    ],
    "overall_confidence": 0.92,
    "image_description": "A grilled chicken breast on a plate",
    "suggestions": ["Great protein choice!", "Consider adding vegetables"],
    "totals": {
      "calories": 165,
      "protein": 31,
      "carbs": 0,
      "fat": 3.6,
      "fiber": 0
    },
    "insights": ["High protein meal", "Low carb option"]
  }
}
```

### Get Nutrition Suggestions
```
POST /api/nutrition-suggestions
Content-Type: application/json

Body: {
  "foodItems": [...],
  "userGoals": {
    "goal": "weight_loss",
    "dailyCalories": 2000,
    "proteinGoal": 150,
    "carbGoal": 200,
    "fatGoal": 67
  }
}
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `OPENAI_API_KEY` | OpenAI API key (required) | - |
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `ALLOWED_ORIGINS` | CORS allowed origins | localhost:3000,8080 |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window | 900000 (15 min) |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | 100 |
| `MAX_IMAGE_SIZE_MB` | Max image file size | 10 |
| `SUPPORTED_FORMATS` | Allowed image formats | jpg,jpeg,png,webp |

### Rate Limiting

- **Window:** 15 minutes
- **Limit:** 100 requests per IP
- **Headers:** Rate limit info included in responses

### Image Processing

- **Max Size:** 10MB (configurable)
- **Formats:** JPG, JPEG, PNG, WebP
- **Optimization:** Automatic resize to 1024x1024 max
- **Quality:** 85% JPEG compression

## Error Handling

The API returns structured error responses:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE",
  "message": "Detailed description"
}
```

### Error Codes

- `NO_IMAGE` - No image provided
- `INVALID_FILE_TYPE` - Unsupported image format
- `FILE_TOO_LARGE` - Image exceeds size limit
- `ANALYSIS_FAILED` - ChatGPT analysis failed
- `RATE_LIMITED` - Too many requests
- `INVALID_FOOD_ITEMS` - Invalid food data
- `SUGGESTIONS_FAILED` - Failed to generate suggestions

## Development

### Project Structure

```
backend/
├── server.js              # Main server file
├── services/
│   ├── chatgptService.js  # ChatGPT Vision integration
│   └── nutritionService.js # Nutrition analysis logic
├── package.json
├── .env.example
└── README.md
```

### Adding Features

1. **New API endpoints:** Add routes in `server.js`
2. **New services:** Create files in `services/` directory
3. **Error handling:** Use structured error responses
4. **Validation:** Add input validation middleware

### Testing

```bash
# Test health endpoint
curl http://localhost:3000/health

# Test food analysis (replace with actual image)
curl -X POST -F "image=@food.jpg" http://localhost:3000/api/analyze-food
```

## Deployment

### Production Considerations

1. **Environment Variables:** Set all required env vars
2. **HTTPS:** Use SSL/TLS in production
3. **Database:** Consider adding PostgreSQL for data persistence
4. **Monitoring:** Add logging and health checks
5. **Scaling:** Use PM2 or Docker for process management

### Docker Deployment

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## Cost Estimation

### OpenAI API Costs (GPT-4V)
- **Per Image:** ~$0.01
- **Monthly (1000 users, 3 images/day):** ~$900
- **Optimization:** Cache results, batch processing

### Server Costs
- **Development:** Free (localhost)
- **Production:** $20-100/month (AWS/Google Cloud)
- **Database:** $10-50/month (if added)

## Troubleshooting

### Common Issues

1. **OpenAI API Key Invalid**
   - Check `.env` file has correct API key
   - Verify key has GPT-4V access

2. **Image Upload Fails**
   - Check file size (max 10MB)
   - Verify image format (JPG/PNG/WebP)
   - Check network connectivity

3. **Rate Limiting**
   - Implement client-side retry logic
   - Consider caching for repeated requests

4. **Analysis Fails**
   - Check OpenAI API status
   - Verify image quality and content
   - Check server logs for detailed errors

## Support

For issues and questions:
1. Check server logs for error details
2. Verify environment configuration
3. Test with simple images first
4. Check OpenAI API status and quotas


