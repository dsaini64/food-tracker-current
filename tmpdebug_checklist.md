# Debug Checklist: No Builds Available

## 1. Check Xcode Cloud Build Status
- [ ] Build phase succeeded
- [ ] Archive phase succeeded  
- [ ] Export/Distribute phase succeeded ← KEY CHECK

## 2. Verify App Store Connect
- [ ] Signed into correct Apple Developer account
- [ ] Looking at correct app
- [ ] Checking TestFlight → iOS builds section
- [ ] Build appears (even if processing)

## 3. Check Build Details
- [ ] Bundle ID matches between Xcode and App Store Connect
- [ ] Version/build number is unique
- [ ] No export errors in logs

## 4. Timeline Check
- [ ] Allow 10-60 minutes for processing after successful upload
- [ ] Check for email notifications from App Store Connect