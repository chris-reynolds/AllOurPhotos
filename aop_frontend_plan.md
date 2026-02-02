# Frontend Migration Plan: Flutter to Vue

## Objective
Replace the Flutter desktop/mobile app (`all_our_photos_app/`) with the Vue 3 + Vuetify frontend (`frontend/`) while:
1. **Maintaining UI familiarity** - Keep the user interface reasonably similar
2. **Preserving all functionality** - No feature loss
3. **Improving user experience** - Better performance, responsiveness, and error handling

---

## Current State Assessment

### Flutter App (`all_our_photos_app/`)
**Screens:**
- `scSignIn` - User authentication
- `scHome` - Main dashboard/home screen
- `scAlbumList` - List of photo albums
- `scAlbumDetail` - Album contents and management
- `scAlbumAddPhoto` - Add photos to albums
- `scSinglePhoto` - Photo detail view with metadata editing
- `scSingleVideo` - Video playback
- `scMetaEditor` - Metadata editing
- `scDBFix` - Database utilities
- `scTesting` - Testing utilities
- `scTypeAheadDlg` - Type-ahead search dialog

**Key Widgets:**
- `wdgPhotoGrid` - Grid layout for photos
- `wdgPhotoTile` - Individual photo tile
- `wdgSnapGrid` - Snap grid display
- `wdgYearGrid` - Yearly photo overview
- `wdgMonthSelector` - Month selection widget
- `wdgImageFilter` - Photo filtering controls
- `wdgImageRotator` - Image rotation tool
- `wdgClipper` - Image cropping tool
- `wdgSelectionBar` - Multi-select toolbar

**Key Features:**
- Photo browsing by date (year/month grids)
- Album creation and management
- Photo metadata editing (caption, location, ranking, tags)
- Image cropping and rotation
- Multi-select operations
- Filtering by ranking, date, location
- Video playback

### Vue Frontend (`frontend/`)
**Current Status:**
- ✅ Modern architecture with Pinia stores
- ✅ Enhanced logging and error handling
- ✅ Vuetify 3 UI framework
- ✅ Basic views implemented: LoginView, MonthGridView, MonthDetailsView, SnapDetailView, AlbumListView, AlbumDetailView, LogsView

**Missing Flutter Features to Implement:**
- Album photo management (add/remove photos)
- Photo metadata editing UI
- Image cropping/rotation UI
- Year grid view
- Multi-select operations
- Video playback view
- Advanced filtering controls
- Type-ahead search
- Batch operations

---

## Phase 1: Feature Parity Analysis

### 1.1 Screen-by-Screen Mapping

Create detailed comparison document:

| Flutter Screen | Vue Equivalent | Status | Notes |
|---------------|----------------|--------|-------|
| scSignIn | LoginView | ✅ Complete | Already implemented |
| scHome | MonthGridView | ✅ Complete | Default home view |
| scAlbumList | AlbumListView | ✅ Complete | Basic list done |
| scAlbumDetail | AlbumDetailView | ⚠️ Partial | Need add/remove photos |
| scSinglePhoto | SnapDetailView | ⚠️ Partial | Need metadata editing |
| scSingleVideo | VideoDetailView | ❌ Missing | New view needed |
| scMetaEditor | Integrated in SnapDetailView | ⚠️ Partial | Need full editing UI |
| scAlbumAddPhoto | Photo picker dialog | ❌ Missing | New component needed |
| scDBFix | N/A | ➖ Skip | Admin feature, not needed initially |
| scTesting | LogsView | ✅ Alternative | Modern logging view |
| Month Details | MonthDetailsView | ✅ Complete | Already implemented |
| Year Grid | YearGridView | ❌ Missing | New view needed |

### 1.2 Widget/Component Mapping

| Flutter Widget | Vue Component | Status | Priority |
|---------------|---------------|--------|----------|
| wdgPhotoGrid | PhotoGrid.vue | ✅ Complete | High |
| wdgPhotoTile | PhotoTile.vue | ✅ Complete | High |
| wdgMonthSelector | MonthSelector.vue | ❌ Missing | High |
| wdgImageFilter | FilterToolbar.vue | ❌ Missing | High |
| wdgSelectionBar | SelectionToolbar.vue | ❌ Missing | High |
| wdgImageRotator | ImageRotator.vue | ❌ Missing | Medium |
| wdgClipper | ImageCropper.vue | ❌ Missing | Medium |
| wdgYearGrid | YearGrid.vue | ❌ Missing | Medium |
| wdgSnapGrid | SnapGrid.vue | ⚠️ Partial | Medium |
| wdgTypeAhead | SearchDialog.vue | ❌ Missing | Low |

### 1.3 Feature Checklist

#### Authentication & Navigation
- [x] User login
- [x] Session management
- [x] Protected routes
- [ ] Remember me functionality
- [ ] Multi-user support

#### Photo Browsing
- [x] Month grid view
- [x] Month details view
- [x] Photo thumbnails
- [x] Photo full view
- [ ] Year grid overview
- [ ] Infinite scroll/pagination
- [ ] Lazy loading images

#### Photo Management
- [x] View photo metadata
- [ ] Edit photo metadata (caption, location, ranking, tags)
- [ ] Rotate photos
- [ ] Crop photos
- [ ] Delete photos
- [ ] Batch operations

#### Album Management
- [x] List albums
- [x] View album contents
- [x] Create album
- [x] Edit album details
- [x] Delete album
- [ ] Add photos to album
- [ ] Remove photos from album
- [ ] Reorder photos in album
- [ ] Album cover selection

#### Filtering & Search
- [x] Basic filtering (in services)
- [ ] Filter by ranking
- [ ] Filter by date range
- [ ] Filter by location
- [ ] Search by caption/tags
- [ ] Type-ahead search
- [ ] Save filter presets

#### Media Support
- [x] Display photos
- [ ] Display videos
- [ ] Video playback controls
- [ ] Thumbnail generation for videos
- [ ] Video metadata

#### Advanced Features
- [ ] Multi-select mode
- [ ] Bulk edit metadata
- [ ] Export photos
- [ ] Print album
- [ ] Sync with Google Photos (if needed)
- [ ] Upload photos

---

## Phase 2: UI/UX Design Reference

### 2.1 Screenshot Documentation
- [ ] Take screenshots of all Flutter screens
- [ ] Document color schemes, spacing, typography
- [ ] Identify key UI patterns (layouts, transitions, dialogs)
- [ ] Note important interactions (gestures, keyboard shortcuts)

### 2.2 Style Guide Creation

**File: `frontend/docs/design_system.md`**

Document:
- Color palette (primary, secondary, accent, backgrounds)
- Typography (font sizes, weights, line heights)
- Spacing system (margins, paddings)
- Component patterns (cards, buttons, toolbars)
- Icons and imagery
- Responsive breakpoints

### 2.3 Vuetify Theme Configuration

**File: `frontend/src/plugins/vuetify.js`**
```javascript
import { createVuetify } from 'vuetify'

export default createVuetify({
  theme: {
    defaultTheme: 'aopTheme',
    themes: {
      aopTheme: {
        dark: false,
        colors: {
          primary: '#1976D2',      // Match Flutter primary
          secondary: '#424242',    // Match Flutter secondary
          accent: '#82B1FF',       // Match Flutter accent
          error: '#FF5252',
          info: '#2196F3',
          success: '#4CAF50',
          warning: '#FFC107',
          background: '#FAFAFA',
          surface: '#FFFFFF',
        }
      }
    }
  }
})
```

---

## Phase 3: Component Development

### 3.1 Core Components (High Priority)

#### Component: MonthSelector.vue
**Purpose:** Allow users to navigate between months
**Flutter Reference:** `wdgMonthSelector`

```vue
<template>
  <v-card>
    <v-card-title>
      <v-btn icon @click="previousYear"><v-icon>mdi-chevron-left</v-icon></v-btn>
      <span>{{ year }}</span>
      <v-btn icon @click="nextYear"><v-icon>mdi-chevron-right</v-icon></v-btn>
    </v-card-title>
    <v-card-text>
      <v-row>
        <v-col v-for="month in 12" :key="month" cols="3">
          <v-btn
            block
            :color="isCurrentMonth(month) ? 'primary' : ''"
            @click="selectMonth(month)"
          >
            {{ monthNames[month - 1] }}
          </v-btn>
        </v-col>
      </v-row>
    </v-card-text>
  </v-card>
</template>
```

**Tasks:**
- [ ] Create component file
- [ ] Implement month navigation
- [ ] Add keyboard shortcuts
- [ ] Highlight current month
- [ ] Emit month selection events

#### Component: FilterToolbar.vue
**Purpose:** Filter photos by ranking, date, location
**Flutter Reference:** `wdgImageFilter`

**Tasks:**
- [ ] Create filter controls (date pickers, dropdowns, sliders)
- [ ] Integrate with snaps store filtering
- [ ] Add "Clear filters" button
- [ ] Show active filter count badge
- [ ] Persist filter state

#### Component: SelectionToolbar.vue
**Purpose:** Multi-select operations toolbar
**Flutter Reference:** `wdgSelectionBar`

**Tasks:**
- [ ] Create floating toolbar for selection mode
- [ ] Add "Select All" / "Select None" buttons
- [ ] Add bulk operations: Delete, Add to Album, Set Ranking
- [ ] Show selection count
- [ ] Exit selection mode

#### Component: ImageEditor.vue
**Purpose:** In-place image rotation and cropping
**Flutter Reference:** `wdgImageRotator`, `wdgClipper`

**Tasks:**
- [ ] Research image cropping libraries (vue-advanced-cropper, cropperjs)
- [ ] Implement rotation (90° increments)
- [ ] Implement freeform cropping
- [ ] Add preset crop ratios (16:9, 4:3, 1:1, etc.)
- [ ] Preview before save
- [ ] Call backend crop/rotate APIs

#### Component: MetadataEditor.vue
**Purpose:** Edit photo metadata
**Flutter Reference:** `scMetaEditor`

**Tasks:**
- [ ] Caption text field
- [ ] Location autocomplete (using /find/locations)
- [ ] Ranking selector (1-5 stars)
- [ ] Tags input (chips)
- [ ] Date/time picker
- [ ] Device name display
- [ ] Save/Cancel buttons
- [ ] Validation

#### Component: YearGrid.vue
**Purpose:** Yearly overview of photos
**Flutter Reference:** `wdgYearGrid`

**Tasks:**
- [ ] Grid layout showing all months
- [ ] Photo count per month
- [ ] Thumbnail preview per month
- [ ] Navigate to month on click
- [ ] Year selector dropdown

### 3.2 Feature Views (High Priority)

#### View: VideoDetailView.vue
**Purpose:** Display and play videos
**Flutter Reference:** `scSingleVideo`

**Tasks:**
- [ ] Video player integration (HTML5 video or video.js)
- [ ] Playback controls
- [ ] Display video metadata
- [ ] Thumbnail display
- [ ] Next/Previous video navigation

#### View: AlbumPhotoPicker.vue
**Purpose:** Add photos to an album
**Flutter Reference:** `scAlbumAddPhoto`

**Tasks:**
- [ ] Photo grid with checkboxes
- [ ] Filter/search photos
- [ ] Show already-added photos (disabled)
- [ ] Bulk add selected photos
- [ ] Pagination for large photo sets

### 3.3 Enhancement Components (Medium Priority)

#### Component: PhotoUploader.vue
**Purpose:** Upload new photos

**Tasks:**
- [ ] Drag-and-drop file upload
- [ ] Multi-file selection
- [ ] Upload progress indicators
- [ ] EXIF extraction preview
- [ ] Batch upload to backend

#### Component: SearchDialog.vue
**Purpose:** Type-ahead search
**Flutter Reference:** `scTypeAheadDlg`

**Tasks:**
- [ ] Search input with autocomplete
- [ ] Search by caption, location, tags
- [ ] Recent searches
- [ ] Navigate to results

---

## Phase 4: View Integration

### 4.1 Enhanced SnapDetailView
**Current:** Basic photo display
**Target:** Full metadata editing, rotation, cropping

**Tasks:**
- [ ] Integrate MetadataEditor component
- [ ] Add rotation buttons (inline)
- [ ] Add crop button (opens ImageEditor dialog)
- [ ] Add "Add to Album" button
- [ ] Add Next/Previous navigation
- [ ] Add keyboard shortcuts (arrow keys, ESC)
- [ ] Display photo info (dimensions, file size, date taken)

### 4.2 Enhanced AlbumDetailView
**Current:** List of album photos
**Target:** Full album management

**Tasks:**
- [ ] Add "Add Photos" button → Opens AlbumPhotoPicker
- [ ] Implement photo removal from album
- [ ] Add drag-to-reorder photos
- [ ] Set album cover photo
- [ ] Edit album name/description inline
- [ ] Show photo count and date range

### 4.3 New YearGridView
**Purpose:** Annual photo overview

**Tasks:**
- [ ] Create route `/year/:year`
- [ ] Integrate YearGrid component
- [ ] Add year selector
- [ ] Link to MonthDetailsView on month click

### 4.4 Enhanced MonthGridView
**Current:** Basic month grid
**Target:** Full navigation and filtering

**Tasks:**
- [ ] Integrate MonthSelector component
- [ ] Add year overview button
- [ ] Show photo statistics
- [ ] Quick filter controls

---

## Phase 5: Store Enhancements

### 5.1 Snaps Store Updates

**File: `frontend/src/stores/snaps.js`**

Add functionality:
- [ ] Multi-select state management
  ```javascript
  selectedSnapIds: [],
  toggleSelection(snapId),
  selectAll(),
  clearSelection(),
  getSelectedSnaps()
  ```
- [ ] Filtering state
  ```javascript
  activeFilters: { ranking: null, startDate: null, endDate: null, location: null },
  applyFilters(),
  clearFilters()
  ```
- [ ] Rotation/crop operations
  ```javascript
  async rotateSnap(snapId, degrees),
  async cropSnap(snapId, coordinates)
  ```

### 5.2 Albums Store Updates

**File: `frontend/src/stores/albums.js`**

Add functionality:
- [ ] Album item management
  ```javascript
  async addPhotosToAlbum(albumId, snapIds),
  async removePhotoFromAlbum(albumId, snapId),
  async reorderAlbumPhotos(albumId, snapIdOrder)
  ```
- [ ] Album cover management
  ```javascript
  async setAlbumCover(albumId, snapId)
  ```

### 5.3 New Settings Store

**File: `frontend/src/stores/settings.js`**

Store user preferences:
- [ ] Grid size (thumbnails per row)
- [ ] Default sort order
- [ ] Filter presets
- [ ] UI preferences (dark mode, etc.)

---

## Phase 6: Service Layer Enhancements

### 6.1 Image Processing Services

**File: `frontend/src/services/imageProcessing.js`**

```javascript
export async function rotateImage(snapId, degrees) {
  // Call /rotate endpoint
}

export async function cropImage(snapId, left, top, right, bottom) {
  // Call /crop endpoint
}

export async function uploadImage(file, metadata) {
  // Call /upload2 endpoint with FormData
}
```

### 6.2 Video Services

**File: `frontend/src/services/video.js`**

```javascript
export function getVideoUrl(snap) {
  return `${API_URL}/photos/${snap.directory}/${snap.file_name}`
}

export function getVideoThumbnailUrl(snap) {
  // Return thumbnail path if available
}
```

---

## Phase 7: Testing & Validation

### 7.1 Component Testing
For each new component:
- [ ] Create component tests (Vitest)
- [ ] Test user interactions
- [ ] Test edge cases
- [ ] Test responsive behavior

### 7.2 Integration Testing
- [ ] Test complete user workflows
- [ ] Test with real backend
- [ ] Test with large photo sets (1000+ photos)
- [ ] Test on different screen sizes

### 7.3 Cross-Browser Testing
- [ ] Chrome/Edge
- [ ] Firefox
- [ ] Safari (if available)

### 7.4 User Acceptance Testing

Create test scenarios based on Flutter app workflows:

**Scenario 1: Browse and edit photos**
1. Login
2. Navigate to a month
3. Click on a photo
4. Edit caption and ranking
5. Rotate image
6. Save changes
7. Verify changes persisted

**Scenario 2: Create and populate album**
1. Create new album
2. Open album
3. Click "Add Photos"
4. Select 10 photos
5. Add to album
6. Verify all photos appear
7. Remove one photo
8. Verify removal

**Scenario 3: Filter and find photos**
1. Apply ranking filter (4-5 stars)
2. Apply date range filter
3. Verify results match filters
4. Clear filters
5. Use search to find specific location
6. Verify search results

---

## Phase 8: Performance Optimization

### 8.1 Image Loading
- [ ] Implement lazy loading (vue-lazyload or Intersection Observer)
- [ ] Use thumbnail URLs for grids
- [ ] Full resolution only for detail view
- [ ] Add loading skeletons

### 8.2 Virtual Scrolling
- [ ] Implement virtual scrolling for large photo grids (vue-virtual-scroller)
- [ ] Test with 10,000+ photos

### 8.3 Caching Strategy
- [ ] Cache API responses in Pinia stores
- [ ] Use browser cache for images
- [ ] Implement stale-while-revalidate pattern

### 8.4 Bundle Optimization
- [ ] Code splitting by route
- [ ] Tree-shake unused Vuetify components
- [ ] Optimize images in `public/`

---

## Phase 9: Deployment Preparation

### 9.1 Build Configuration
- [ ] Configure production build settings
- [ ] Set up environment variables for production
- [ ] Optimize Vite config for production

**File: `frontend/vite.config.js`**
```javascript
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vuetify': ['vuetify'],
          'vendor': ['vue', 'vue-router', 'pinia', 'axios']
        }
      }
    },
    chunkSizeWarningLimit: 1000
  }
})
```

### 9.2 Backend Integration
- [ ] Configure backend to serve Vue build
  ```javascript
  // backend/src/server.js
  app.use(express.static(path.join(__dirname, '../../frontend/dist')))
  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, '../../frontend/dist/index.html'))
  })
  ```
- [ ] Test production build with backend

### 9.3 Documentation
- [ ] User guide (how to use new interface)
- [ ] Migration guide (differences from Flutter app)
- [ ] Developer documentation

---

## Phase 10: Gradual Rollout

### 10.1 Beta Testing
Week 1-2:
- [ ] Deploy to test environment
- [ ] Invite beta testers (2-3 users)
- [ ] Collect feedback on UI/UX
- [ ] Fix critical bugs

### 10.2 Feature Flags
Implement feature toggles for:
- [ ] Image editing (crop/rotate)
- [ ] Multi-select operations
- [ ] Video playback
- [ ] Advanced filters

Allow gradual enablement of features.

### 10.3 Parallel Running
- [ ] Keep Flutter app available as fallback
- [ ] Provide "Switch to Classic View" option initially
- [ ] Monitor usage patterns
- [ ] Collect user feedback

### 10.4 Full Migration
After 4 weeks of stable Vue app usage:
- [ ] Make Vue app the default
- [ ] Archive Flutter app code
- [ ] Update documentation

---

## Implementation Timeline

| Week | Phase | Deliverables |
|------|-------|-------------|
| 1 | Phase 1-2 | Feature analysis, UI documentation |
| 2-3 | Phase 3 | Core components (MonthSelector, FilterToolbar, SelectionToolbar) |
| 4-5 | Phase 3 | Image editing components (ImageEditor, MetadataEditor) |
| 6 | Phase 3 | YearGrid, VideoDetailView |
| 7-8 | Phase 4 | View integration (enhanced SnapDetail, AlbumDetail) |
| 9 | Phase 5 | Store enhancements (multi-select, filtering) |
| 10 | Phase 6-7 | Service layer, testing |
| 11 | Phase 8 | Performance optimization |
| 12 | Phase 9-10 | Deployment, beta testing, rollout |

---

## Success Criteria

The Vue frontend is ready to replace Flutter when:

✅ **Feature Complete**: All Flutter features implemented
✅ **UI Consistent**: Visual design matches Flutter app closely
✅ **Performance**: Loads 500 photos in under 3 seconds
✅ **Responsive**: Works on desktop and tablet sizes
✅ **Tested**: All workflows tested and validated
✅ **User Approved**: Beta testers confirm usability
✅ **Error Handling**: Graceful error handling and logging
✅ **Accessible**: Keyboard navigation works

---

## Priority Order for Implementation

### Must Have (Phase 1)
1. ✅ Login and authentication
2. ✅ Month grid and month details
3. ✅ Photo viewing
4. ⚠️ Basic metadata editing
5. ⚠️ Album management (add/remove photos)

### Should Have (Phase 2)
6. Image rotation
7. Filtering by ranking/date
8. Multi-select operations
9. Year grid view
10. Video playback

### Nice to Have (Phase 3)
11. Image cropping
12. Advanced search
13. Photo upload
14. Batch operations
15. Export features

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Users resist UI change | High | Keep UI very similar, provide training |
| Performance issues with large photo sets | High | Implement virtual scrolling early |
| Image editing quality concerns | Medium | Match Flutter output exactly, A/B test |
| Browser compatibility issues | Medium | Test early on all target browsers |
| Missing Flutter features discovered late | Medium | Thorough feature inventory upfront |
| Development takes longer than expected | Low | Prioritize must-have features first |

---

## Development Best Practices

1. **Incremental Development**: Build one component at a time, test thoroughly
2. **Reference Flutter**: Keep Flutter app running for UI/UX reference
3. **User Feedback**: Show components to users early and often
4. **Responsive First**: Design for both desktop and tablet from the start
5. **Accessibility**: Add ARIA labels, keyboard shortcuts from the beginning
6. **Performance**: Test with large datasets (1000+ photos) regularly
7. **Error Handling**: Use existing logging/error infrastructure
8. **Code Review**: Review each component before integration
