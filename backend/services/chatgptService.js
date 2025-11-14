const OpenAI = require('openai');

class ChatGPTService {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });
  }

  async analyzeFoodImage(base64Image) {
    try {
      // Reduced logging for production performance
      if (process.env.NODE_ENV !== 'production') {
        console.log('🤖 ChatGPT Service: Starting analysis...');
        console.log('🤖 Image size:', base64Image.length, 'characters');
      }
      
      const prompt = `
        Analyze this food image and provide detailed nutrition information. 
        
        Please identify:
        1. All food items visible in the image
        2. Estimated portion sizes
        3. Cooking methods (grilled, fried, raw, etc.)
        4. Nutritional content for each item
        
        For each food item, provide:
        - name: Clear, SPECIFIC food name with details (e.g., "red apple" not just "apple", "grilled chicken breast" not just "chicken", "steamed broccoli" not just "broccoli"). Include color, preparation method, or other distinguishing features when visible.
        - calories: Estimated calories per serving
        - protein: Protein in grams
        - carbs: Carbohydrates in grams  
        - fat: Fat in grams
        - fiber: Fiber in grams (if applicable)
        - serving_size: Estimated serving size description
        - confidence: Your confidence level (0-1)
        - cooking_method: How the food appears to be prepared
        - health_notes: Any health considerations or tips
        - ingredients: Array of main ingredients detected (e.g., ["chicken", "rice", "broccoli"])
        - portion_size: Estimated portion size as "small", "medium", or "large" based on visual appearance
        - macro_guess: Primary macronutrient appearance as "carb-heavy", "protein-rich", "fat-heavy", or "balanced" based on visual characteristics
        
        Return the response as a JSON object with this structure:
        {
          "foods": [
            {
              "name": "string",
              "calories": number,
              "protein": number,
              "carbs": number,
              "fat": number,
              "fiber": number,
              "serving_size": "string",
              "confidence": number,
              "cooking_method": "string",
              "health_notes": "string",
              "ingredients": ["string"],
              "portion_size": "small" | "medium" | "large",
              "macro_guess": "carb-heavy" | "protein-rich" | "fat-heavy" | "balanced"
            }
          ],
          "overall_confidence": number,
          "image_description": "string",
          "suggestions": ["string"]
        }
        
        Be as accurate as possible with nutrition estimates. Consider the visual portion size and cooking method.
      `;

      if (process.env.NODE_ENV !== 'production') {
        console.log('🤖 Calling OpenAI API...');
      }
      const response = await this.openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: [
              {
                type: "text",
                text: prompt
              },
              {
                type: "image_url",
                image_url: {
                  url: `data:image/jpeg;base64,${base64Image}`,
                  detail: "auto" // Auto selects optimal detail level for faster processing
                }
              }
            ]
          }
        ],
        max_tokens: 1500, // Reduced from 2000 for faster responses
        temperature: 0.3
      });
      
      const content = response.choices[0].message.content;
      
      if (process.env.NODE_ENV !== 'production') {
        console.log('🤖 OpenAI API response received');
        console.log('🤖 Raw ChatGPT response:', content);
      }
      
      // Parse JSON response
      let analysis;
      try {
        // Extract JSON from response (in case there's extra text)
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          analysis = JSON.parse(jsonMatch[0]);
          
          // Add IDs to foods if they don't have them
          // Also ensure optional fields have defaults
          if (analysis.foods && Array.isArray(analysis.foods)) {
            analysis.foods = analysis.foods.map((food, index) => ({
              id: food.id || `food_${Date.now()}_${index}`,
              ingredients: food.ingredients || [],
              portion_size: food.portion_size || 'medium',
              macro_guess: food.macro_guess || 'balanced',
              ...food
            }));
          }
          
          // Convert snake_case to camelCase for iOS compatibility
          if (analysis.overall_confidence !== undefined) {
            analysis.overallConfidence = analysis.overall_confidence;
            delete analysis.overall_confidence;
          }
          if (analysis.image_description !== undefined) {
            analysis.imageDescription = analysis.image_description;
            delete analysis.image_description;
          }
          
          // Process foods array
          if (analysis.foods && Array.isArray(analysis.foods)) {
            analysis.foods = analysis.foods.map(food => {
              return food;
            });
          }
        } else {
          throw new Error('No JSON found in response');
        }
      } catch (parseError) {
        console.error('Error parsing ChatGPT response:', parseError);
        console.error('Raw response:', content);
        
        // Fallback: create a basic response
        analysis = {
          foods: [{
            id: `food_${Date.now()}_0`, // Add unique ID
            name: "Unidentified Food",
            calories: 0,
            protein: 0,
            carbs: 0,
            fat: 0,
            fiber: 0,
            serving_size: "Unknown",
            confidence: 0.1,
            cooking_method: "Unknown",
            health_notes: "Unable to identify food item"
          }],
          overallConfidence: 0.1,
          imageDescription: "Unable to analyze image",
          suggestions: ["Try taking a clearer photo with better lighting"]
        };
        
        // Process fallback response
        if (analysis.foods && Array.isArray(analysis.foods)) {
          analysis.foods = analysis.foods.map(food => {
            return food;
          });
        }
      }

      return analysis;

    } catch (error) {
      console.error('ChatGPT API Error:', error);
      
      if (error.status === 401) {
        throw new Error('Invalid OpenAI API key');
      } else if (error.status === 429) {
        throw new Error('OpenAI API rate limit exceeded');
      } else if (error.status === 400) {
        throw new Error('Invalid request to OpenAI API');
      } else {
        throw new Error(`OpenAI API error: ${error.message}`);
      }
    }
  }

  async getNutritionAdvice(foodItems, userGoals) {
    try {
      const prompt = `
        Based on these food items and user goals, provide personalized nutrition advice:
        
        Food Items: ${JSON.stringify(foodItems)}
        User Goals: ${JSON.stringify(userGoals)}
        
        Provide:
        1. Overall nutrition assessment
        2. Suggestions for improvement
        3. Meal timing recommendations
        4. Portion size advice
        5. Health tips
        
        Return as JSON with fields: assessment, suggestions, meal_timing, portion_advice, health_tips
      `;

      const response = await this.openai.chat.completions.create({
        model: "gpt-4",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 1000,
        temperature: 0.4
      });

      return JSON.parse(response.choices[0].message.content);

    } catch (error) {
      console.error('Error getting nutrition advice:', error);
      throw new Error('Failed to generate nutrition advice');
    }
  }
}

module.exports = new ChatGPTService();


