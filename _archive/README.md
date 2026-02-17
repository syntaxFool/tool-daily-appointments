# Legacy Files Archive

This folder contains the original Progressive Web App (PWA) implementation and related documentation from before the project standardized on the Flutter cross-platform app.

## Contents

### Frontend (PWA)
- **stylist_access_simple.html** - Standalone HTML/CSS/JavaScript PWA for browsers
- **sw.js** - Service Worker for offline support and caching
- **manifest.json** - PWA manifest configuration

### Documentation
- **PWA_SETUP_FREE.md** - Original PWA deployment guide
- **STYLIST_SETUP.md** - Token management and stylist setup instructions
- **plan.md** - Original project specification and planning notes

## Why Archived?

The project transitioned from PWA to Flutter for these reasons:

1. **Better offline support** - Flutter has more robust caching than Service Workers
2. **Native app experience** - Can be installed on app stores and home screens
3. **Performance** - Compiled Flutter is faster than JavaScript PWA
4. **Cross-platform** - Single codebase for iOS, Android, web, and desktop
5. **Easier maintenance** - Dart is more strongly typed than JavaScript

## If You Need the PWA

To use the legacy PWA:

1. Copy `stylist_access_simple.html`, `sw.js`, and `manifest.json` to a web server
2. Update `manifest.json` with correct app name and colors
3. Update the API endpoint URL in the HTML file
4. Serve over HTTPS (required for Service Workers)

## Migration Path

If you have PWA users:

1. Host both PWA and Flutter web versions temporarily
2. Add a banner in PWA suggesting Flutter app download
3. Gradually migrate users to native/Flutter app
4. Retire PWA once adoption is complete

---

**Status**: Archived  
**Last Update**: February 18, 2026  
**Recommendation**: Use Flutter app for all new features
