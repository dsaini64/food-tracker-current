const OpenAI = require('openai');

class PatternSummaryService {
  constructor() {
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });
  }

  async generatePatternSummary(mealsToday) {
    try {
      if (process.env.NODE_ENV !== 'production') {
        console.log('📊 Pattern Summary Service: Generating summary for', mealsToday.length, 'meals');
      }

      // Build the input data for GPT
      // Handle both camelCase (from Swift) and snake_case formats
      const mealsData = mealsToday.map(meal => ({
        timestamp: meal.timestamp,
        detected_ingredients: meal.ingredients || meal.detected_ingredients || [],
        cuisine_guess: meal.cuisine || meal.cuisine_guess || null,
        portion_size_estimate: meal.portionSize || meal.portion_size_estimate || 'medium',
        meal_type_guess: meal.mealType || meal.meal_type_guess || 'snack',
        location: meal.location || 'home',
        macro_appearance_estimate: meal.macroGuess || meal.macro_appearance_estimate || 'balanced',
        calories: meal.calories || 0,
        carbs: meal.carbs || 0,
        protein: meal.protein || 0,
        fat: meal.fat || 0
      }));

      // Extract patterns from the data
      const patterns = this.extractPatterns(mealsToday);

      const prompt = `You are generating a daily eating pattern summary for a food-tracking app. 

The summary must be 100% descriptive and must NOT give advice, evaluations, nutrition judgments, recommendations, or health conclusions. It must remain fully App-Store–safe under guideline 1.4.1, meaning: 

- No statements about what the user should eat. 
- No statements about healthiness, diet quality, risks, or medical impact. 
- No nutritional judgments (e.g., "too much sugar," "high-fat meal," "unhealthy," "better choices"). 
- Only objective observations, patterns, frequencies, and comparisons.

INPUT YOU WILL RECEIVE:

Meals for today:
${JSON.stringify(mealsData, null, 2)}

Extracted patterns:
${JSON.stringify(patterns, null, 2)}

TASK:

Using ONLY the provided data, produce:

1. A concise 3–6 bullet "Today's Eating Pattern Summary" that highlights interesting observational patterns from the day.

2. A single short sentence that summarizes the day's meals in a friendly but still fully descriptive tone.

RULES:

- Do NOT use any evaluative words like "healthy," "unhealthy," "balanced," "better," "worse," "should," "avoid," or anything implying advice.
- ONLY describe what can be directly inferred from the input data.
- If data is incomplete or minimal, still produce a short summary based on what is available.
- Stay neutral, factual, and helpful.
- Make it feel intelligent but never prescriptive.

FORMAT:

Return exactly this JSON structure:
{
  "summary": "Today's Eating Pattern",
  "bullets": [
    "bullet 1",
    "bullet 2",
    "bullet 3",
    "bullet 4"
  ],
  "overall": "1 short sentence summary"
}

Ensure the bullets are interesting, descriptive, and based on the actual data provided.`;

      const response = await this.openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          {
            role: "user",
            content: prompt
          }
        ],
        max_tokens: 500,
        temperature: 0.3
      });

      const content = response.choices[0].message.content;
      
      // Parse JSON response
      let summary;
      try {
        const jsonMatch = content.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          summary = JSON.parse(jsonMatch[0]);
        } else {
          throw new Error('No JSON found in response');
        }
      } catch (parseError) {
        console.error('Error parsing pattern summary response:', parseError);
        // Fallback summary
        summary = {
          summary: "Today's Eating Pattern",
          bullets: [
            "No patterns detected yet",
            "Continue logging meals to see insights"
          ],
          overall: "Start tracking your meals to see eating patterns emerge."
        };
      }

      return summary;

    } catch (error) {
      console.error('Pattern Summary Service Error:', error);
      
      // Return a safe fallback
      return {
        summary: "Today's Eating Pattern",
        bullets: [
          "Unable to generate pattern summary",
          "Please try again later"
        ],
        overall: "Pattern analysis is currently unavailable."
      };
    }
  }

  extractPatterns(meals) {
    if (!meals || meals.length === 0) {
      return {};
    }

    const patterns = {
      first_meal_time: null,
      latest_meal_time: null,
      largest_portion: null,
      ingredient_frequency: {},
      macro_distribution: {
        carb_heavy: 0,
        protein_rich: 0,
        fat_heavy: 0,
        balanced: 0
      },
      meal_type_distribution: {},
      location_distribution: {}
    };

    // Find first and latest meal times
    const sortedByTime = meals.sort((a, b) => 
      new Date(a.timestamp) - new Date(b.timestamp)
    );
    if (sortedByTime.length > 0) {
      patterns.first_meal_time = sortedByTime[0].timestamp;
      patterns.latest_meal_time = sortedByTime[sortedByTime.length - 1].timestamp;
    }

    // Find largest portion (by calories)
    const largestMeal = meals.reduce((max, meal) => 
      (meal.calories || 0) > (max.calories || 0) ? meal : max, meals[0]
    );
    if (largestMeal) {
      patterns.largest_portion = {
        meal_type: largestMeal.mealType || largestMeal.meal_type_guess || 'snack',
        calories: largestMeal.calories || 0,
        portion_size: largestMeal.portionSize || largestMeal.portion_size_estimate || 'medium'
      };
    }

    // Count ingredient frequency
    meals.forEach(meal => {
      const ingredients = meal.ingredients || meal.detected_ingredients || [];
      if (Array.isArray(ingredients) && ingredients.length > 0) {
        ingredients.forEach(ingredient => {
          patterns.ingredient_frequency[ingredient] = 
            (patterns.ingredient_frequency[ingredient] || 0) + 1;
        });
      }
    });

    // Count macro distribution
    meals.forEach(meal => {
      const macroGuess = meal.macroGuess || meal.macro_appearance_estimate || 'balanced';
      if (macroGuess) {
        const macro = macroGuess.toLowerCase();
        if (macro.includes('carb')) {
          patterns.macro_distribution.carb_heavy++;
        } else if (macro.includes('protein')) {
          patterns.macro_distribution.protein_rich++;
        } else if (macro.includes('fat')) {
          patterns.macro_distribution.fat_heavy++;
        } else {
          patterns.macro_distribution.balanced++;
        }
      }
    });

    // Count meal type distribution
    meals.forEach(meal => {
      const mealType = meal.mealType || meal.meal_type_guess || 'snack';
      patterns.meal_type_distribution[mealType] = 
        (patterns.meal_type_distribution[mealType] || 0) + 1;
    });

    // Count location distribution
    meals.forEach(meal => {
      const location = meal.location || 'home';
      patterns.location_distribution[location] = 
        (patterns.location_distribution[location] || 0) + 1;
    });

    return patterns;
  }
}

module.exports = new PatternSummaryService();

