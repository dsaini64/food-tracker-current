# 🚀 Food Tracker App Deployment Guide

## 📱 iOS App Deployment (App Store)

### Step 1: Archive iOS App
1. **Open Xcode**
2. **Select your device** (not simulator)
3. **Product → Archive**
4. **Wait for archive to complete**

### Step 2: Upload to App Store Connect
1. **Window → Organizer**
2. **Select your archive**
3. **Click "Distribute App"**
4. **Choose "App Store Connect"**
5. **Follow upload wizard**

### Step 3: TestFlight Beta Testing
1. **Go to [App Store Connect](https://appstoreconnect.apple.com)**
2. **Select your app**
3. **Go to TestFlight tab**
4. **Add internal/external testers**
5. **Submit for review**

## 🖥️ Backend Deployment (Railway)

### Step 1: Deploy Backend
1. **Go to [railway.app](https://railway.app)**
2. **Sign in with GitHub**
3. **New Project → Deploy from GitHub**
4. **Select `dsaini64/food-tracker-current`**
5. **⚠️ IMPORTANT: Select `backend` folder as root**
6. **Set environment variables:**
   ```
   NODE_ENV=production
   OPENAI_API_KEY=your-openai-api-key-here
   ALLOWED_ORIGINS=*
   ```

### Step 2: Get Railway URL
1. **After deployment, copy your Railway URL**
2. **It will look like: `https://foodtracker-production-xxxx.up.railway.app`**

### Step 3: Update iOS App
1. **Open `FoodAnalysisService.swift`**
2. **Replace the baseURL:**
   ```swift
   private let baseURL = "https://your-actual-railway-url.railway.app"
   ```
3. **Build and test the iOS app**

## 🔄 Complete Deployment Flow

### For Development:
- **iOS app** → Runs on your iPhone (simulator/device)
- **Backend** → Runs on Railway (cloud)
- **Communication** → HTTPS API calls

### For TestFlight:
- **iOS app** → TestFlight beta testers
- **Backend** → Railway (same as development)
- **Communication** → HTTPS API calls

### For App Store:
- **iOS app** → App Store (public release)
- **Backend** → Railway (production)
- **Communication** → HTTPS API calls

## ✅ Testing Checklist

### Backend Testing:
- [ ] Railway deployment successful
- [ ] Health check: `https://your-app.railway.app/health`
- [ ] API test: Upload image to `/api/analyze-food`

### iOS App Testing:
- [ ] App builds without errors
- [ ] Camera functionality works
- [ ] Food analysis works with Railway backend
- [ ] UI displays results correctly

### End-to-End Testing:
- [ ] Take photo of food
- [ ] Analysis appears in app
- [ ] Results are accurate
- [ ] No crashes or errors

## 🎯 Final Result

**Your food tracker app will work for all users:**
- **iOS app** → Available on App Store
- **Backend** → Running on Railway cloud
- **AI Analysis** → ChatGPT Vision via Railway API
- **No local setup required** for users!

## 📞 Support

If you encounter issues:
1. **Check Railway logs** for backend errors
2. **Check Xcode console** for iOS errors
3. **Verify API connectivity** between app and Railway
4. **Test with different food images**
