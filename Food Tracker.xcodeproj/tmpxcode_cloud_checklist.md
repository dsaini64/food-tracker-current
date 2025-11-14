# Xcode Cloud App Store Connect Build Checklist

## Pre-Build Requirements
- [ ] Archive action enabled in workflow
- [ ] Distribution to App Store Connect configured
- [ ] Valid App Store Connect API key (if using)
- [ ] Provisioning profiles set up for distribution
- [ ] Code signing certificates valid

## Build Process
1. Trigger build through one of these methods:
   - Manual trigger from Xcode
   - Push to configured branch
   - Create and push tag
   - Pull request (if configured)

## Post-Build Verification
- [ ] Check Xcode Cloud dashboard for build status
- [ ] Verify archive was created successfully
- [ ] Confirm upload to App Store Connect/TestFlight
- [ ] Check App Store Connect for the new build

## Troubleshooting
- Build logs available in Xcode Cloud dashboard
- App Store Connect processing status
- TestFlight build availability