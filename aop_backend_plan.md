# Backend Migration Testing Plan

## Objective
Parallel test the Python FastAPI backend (`pyserver/`) against the Node/Express backend (`backend/`) to ensure:
1. **No functionality is lost** - All API endpoints work identically
2. **Performance is similar or better** - Response times and throughput are acceptable
3. **Data integrity is maintained** - Database operations produce identical results

---

## Phase 1: Test Environment Setup

### 1.1 Database Preparation
- [ ] Create a test database snapshot from production/staging
- [ ] Set up two identical test databases:
  - `allourphotos_test_python` - For Python backend
  - `allourphotos_test_node` - For Node backend
- [ ] Populate both with identical test data
- [ ] Document test data set (users, sessions, albums, snaps counts)

### 1.2 Backend Configuration
- [ ] Configure Python backend for test database
  - Update `pyserver/config.json` with test DB credentials
  - Set test photos directory
- [ ] Configure Node backend for test database
  - Create `backend/.env.test` with test DB credentials
  - Set test photos directory (same as Python)
- [ ] Ensure both backends use the same photo storage directory

### 1.3 Test Infrastructure
- [ ] Install testing tools:
  ```bash
  npm install -g artillery newman
  ```
- [ ] Set up test runner environment (Python)
  ```bash
  cd pyserver
  python -m venv test_env
  source test_env/bin/activate  # or test_env\Scripts\activate on Windows
  pip install pytest requests httpx
  ```
- [ ] Create test data fixtures in `tests/fixtures/`

---

## Phase 2: Functional Equivalence Testing

### 2.1 Endpoint Inventory
Create comprehensive endpoint checklist:

#### Authentication Endpoints
- [ ] `GET /ses/{user}/{password}/{source}` - Login/session creation
  - Test successful login
  - Test failed login
  - Verify cookie/header setting
  - Verify session creation in database

#### CRUD Endpoints (for each resource: albums, snaps, sessions, users, album_items)
- [ ] `POST /` - Create operation
  - Test valid data
  - Test invalid data
  - Test missing required fields
  - Verify database insertion
  - Check response format

- [ ] `GET /:id` - Read single operation
  - Test existing ID
  - Test non-existent ID
  - Verify response fields match

- [ ] `GET /` - List operation
  - Test without parameters
  - Test with `where` clause
  - Test with `orderby`
  - Test with `limit` and `offset`
  - Test complex query combinations
  - Verify result counts match

- [ ] `PUT /` - Update operation
  - Test valid updates
  - Test partial updates
  - Test invalid data
  - Verify database changes

- [ ] `DELETE /:id` - Delete operation
  - Test deletion
  - Test non-existent ID
  - Verify database deletion

#### Custom Endpoints
- [ ] `GET /version` - Version info
- [ ] `GET /find/:key` - Named SQL queries
  - Test all query keys: monthgrid, locations, nameExists, cropCount, albumSnaps, sessionUser
  - Test parameter substitution
- [ ] `GET /crop/:id/:left/:top/:right/:bottom` - Image cropping
  - Test valid crop coordinates
  - Test edge cases (0,0,0,0)
  - Verify output image dimensions
- [ ] `GET /rotate/:angle/:path` - Image rotation
  - Test 90, 180, 270 degree rotations
  - Verify output image orientation
- [ ] `POST /upload2/:modified/:filename/:sourceDevice` - Image upload
  - Test image upload
  - Test video upload
  - Verify file storage
  - Verify database record creation
  - Verify EXIF extraction
  - Verify thumbnail generation
- [ ] `GET /photos/:path` - Serve photo files
  - Test existing photos
  - Test non-existent photos
  - Test subdirectories
- [ ] `PUT /photos/:path` - Update photo files
  - Test file updates
  - Verify file changes

### 2.2 Test Script Creation

Create automated test suite in `tests/backend_comparison/`:

**File: `tests/backend_comparison/test_endpoints.py`**
```python
import pytest
import requests
import time
from typing import Dict, Any

PYTHON_BASE = "http://localhost:8000"
NODE_BASE = "http://localhost:8001"

class TestBackendComparison:
    def compare_responses(self, python_resp, node_resp, endpoint: str):
        """Compare two API responses for equivalence"""
        assert python_resp.status_code == node_resp.status_code, \
            f"{endpoint}: Status codes differ"

        # Compare response data (order-independent)
        python_data = python_resp.json()
        node_data = node_resp.json()

        # Handle list responses (may have different ordering)
        if isinstance(python_data, list):
            assert len(python_data) == len(node_data), \
                f"{endpoint}: List lengths differ"
        else:
            # Compare dict responses
            assert python_data == node_data, \
                f"{endpoint}: Response data differs"

    def test_version(self):
        """Test /version endpoint"""
        py_resp = requests.get(f"{PYTHON_BASE}/version")
        node_resp = requests.get(f"{NODE_BASE}/version")
        assert py_resp.status_code == 200
        assert node_resp.status_code == 200

    def test_login_success(self):
        """Test successful login"""
        py_resp = requests.get(f"{PYTHON_BASE}/ses/testuser/testpass/pytest")
        node_resp = requests.get(f"{NODE_BASE}/ses/testuser/testpass/pytest")
        self.compare_responses(py_resp, node_resp, "login")

    # Add more tests for each endpoint...
```

**File: `tests/backend_comparison/test_crud.py`**
- CRUD operation tests for each resource

**File: `tests/backend_comparison/test_images.py`**
- Image upload, crop, rotate tests
- File serving tests

### 2.3 Response Format Validation
- [ ] Create JSON schema validators for each endpoint
- [ ] Verify field types match (int vs string, date formats)
- [ ] Check null handling consistency
- [ ] Verify error response formats match

---

## Phase 3: Performance Testing

### 3.1 Load Testing Setup

**File: `tests/performance/artillery_config.yml`**
```yaml
config:
  target: "http://localhost:8000"  # Switch between 8000 (Python) and 8001 (Node)
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 120
      arrivalRate: 20
      name: "Sustained load"
    - duration: 60
      arrivalRate: 50
      name: "Peak load"

scenarios:
  - name: "List snaps"
    flow:
      - get:
          url: "/snaps/?limit=100"
          headers:
            Preserve: '{"jam": "{{sessionId}}"}'

  - name: "Get single snap"
    flow:
      - get:
          url: "/snaps/{{snapId}}"

  - name: "Filter snaps by date"
    flow:
      - get:
          url: "/snaps/?where=taken_date>'2023-01-01'&orderby=taken_date&limit=50"

  - name: "List albums"
    flow:
      - get:
          url: "/albums/?orderby=name"
```

### 3.2 Performance Metrics

Create performance comparison script:

**File: `tests/performance/compare_performance.sh`**
```bash
#!/bin/bash

echo "Testing Python Backend..."
artillery run --target http://localhost:8000 artillery_config.yml -o python_results.json

echo "Testing Node Backend..."
artillery run --target http://localhost:8001 artillery_config.yml -o node_results.json

echo "Generating comparison report..."
node generate_comparison.js
```

**Metrics to track:**
- [ ] Response times (p50, p95, p99)
- [ ] Requests per second
- [ ] Error rates
- [ ] Memory usage
- [ ] CPU usage
- [ ] Database connection pool utilization

### 3.3 Specific Performance Tests

Create test cases for:
- [ ] **Batch operations**: Get 1000 snaps
- [ ] **Complex queries**: Multi-condition WHERE clauses
- [ ] **Image operations**: Upload 100 images sequentially
- [ ] **Image processing**: Crop/rotate 50 images
- [ ] **Concurrent users**: 50 simultaneous sessions
- [ ] **Large result sets**: Queries returning 5000+ records

---

## Phase 4: Edge Cases and Error Handling

### 4.1 Error Response Testing
- [ ] Invalid authentication (401 responses)
- [ ] Missing parameters (400 responses)
- [ ] Resource not found (404 responses)
- [ ] Invalid data types
- [ ] SQL injection attempts (should be prevented)
- [ ] Malformed JSON
- [ ] Extra large payloads

### 4.2 Database Constraint Testing
- [ ] Foreign key violations
- [ ] Unique constraint violations
- [ ] NULL constraint violations
- [ ] Transaction rollback scenarios

### 4.3 File Operation Testing
- [ ] Upload very large images (50MB+)
- [ ] Upload unsupported file types
- [ ] Access files outside photos directory (path traversal)
- [ ] Missing file handling
- [ ] Corrupted image files

---

## Phase 5: Data Consistency Testing

### 5.1 Database State Verification
After each test, verify:
- [ ] Record counts match between test databases
- [ ] Field values are identical
- [ ] Timestamps are within acceptable tolerance
- [ ] Foreign key relationships are maintained

### 5.2 File System Verification
- [ ] Uploaded files exist in same location
- [ ] File sizes match
- [ ] Thumbnails are generated consistently
- [ ] Processed images (cropped/rotated) are equivalent

### 5.3 Create Data Diff Tool

**File: `tests/verification/db_diff.py`**
```python
import mysql.connector
from deepdiff import DeepDiff

def compare_tables(table_name, conn1, conn2):
    """Compare table contents between two databases"""
    cursor1 = conn1.cursor(dictionary=True)
    cursor2 = conn2.cursor(dictionary=True)

    cursor1.execute(f"SELECT * FROM {table_name} ORDER BY id")
    cursor2.execute(f"SELECT * FROM {table_name} ORDER BY id")

    rows1 = cursor1.fetchall()
    rows2 = cursor2.fetchall()

    diff = DeepDiff(rows1, rows2, ignore_order=True)
    return diff
```

---

## Phase 6: Integration Testing with Frontend

### 6.1 End-to-End Testing
- [ ] Point Vue frontend to Python backend, perform complete workflows
- [ ] Point Vue frontend to Node backend, perform same workflows
- [ ] Compare results and user experience

### 6.2 Workflow Tests
Create Playwright/Cypress tests for:
- [ ] Login → Browse photos → View details
- [ ] Create album → Add photos → Delete album
- [ ] Upload photo → Edit metadata → Save
- [ ] Filter photos by date → Change filters
- [ ] Browse month grid → View month details

---

## Phase 7: Migration Preparation

### 7.1 Performance Tuning (if needed)
Based on test results:
- [ ] Optimize slow Node endpoints
- [ ] Add database indexes if needed
- [ ] Configure connection pooling
- [ ] Adjust timeout settings

### 7.2 Configuration Alignment
- [ ] Ensure all config.json queries work in Node backend
- [ ] Verify environment variable handling
- [ ] Test CORS configuration
- [ ] Validate file path handling (Windows/Linux)

### 7.3 Documentation
- [ ] Document any behavioral differences found
- [ ] Create migration runbook
- [ ] Document rollback procedure
- [ ] Update API documentation for any changes

---

## Phase 8: Gradual Migration Strategy

### 8.1 Dual-Backend Setup
- [ ] Configure reverse proxy (nginx) to route to both backends:
  ```nginx
  upstream backend {
      server localhost:8000;  # Python - primary
      server localhost:8001;  # Node - backup
  }
  ```
- [ ] Implement health checks
- [ ] Set up monitoring/logging

### 8.2 Canary Deployment
Week 1:
- [ ] Route 10% of traffic to Node backend
- [ ] Monitor error rates and performance
- [ ] Compare logs between backends

Week 2-3:
- [ ] Gradually increase to 50% traffic
- [ ] Continue monitoring

Week 4:
- [ ] Route 100% traffic to Node backend
- [ ] Keep Python backend running as fallback

### 8.3 Final Cutover
- [ ] Run Node backend exclusively for 1 week
- [ ] Monitor for issues
- [ ] If stable, decommission Python backend
- [ ] Archive `pyserver/` code

---

## Success Criteria

The Node backend is ready for production when:

✅ **Functional**: All automated tests pass with 100% equivalence
✅ **Performance**: Response times within 10% of Python backend
✅ **Reliability**: Error rate < 0.1% under load
✅ **Capacity**: Handles 50 concurrent users without degradation
✅ **Data Integrity**: No data inconsistencies detected
✅ **Integration**: Frontend works seamlessly with Node backend
✅ **Monitoring**: Logging and metrics collection in place

---

## Test Execution Timeline

| Week | Activities |
|------|-----------|
| 1 | Phase 1: Environment setup, test data creation |
| 2 | Phase 2: Functional equivalence testing (CRUD) |
| 3 | Phase 2: Functional equivalence testing (Custom endpoints) |
| 4 | Phase 3: Performance testing and optimization |
| 5 | Phase 4: Edge cases and error handling |
| 6 | Phase 5: Data consistency verification |
| 7 | Phase 6: Integration testing with frontend |
| 8-11 | Phase 8: Gradual migration (canary deployment) |
| 12 | Final validation and cutover |

---

## Test Tracking

Use this checklist format:

```markdown
## Test Run: [Date]
Backend: Python / Node
Tester: [Name]

### Results
- [ ] All CRUD tests passed
- [ ] All custom endpoint tests passed
- [ ] Performance within acceptable range
- [ ] No data inconsistencies found
- [ ] Integration tests passed

### Issues Found
1. [Issue description] - Severity: High/Medium/Low
   - Steps to reproduce:
   - Expected vs Actual:
   - Resolution:

### Notes
[Any observations or concerns]
```

---

## Automated Daily Regression

Set up cron job to run comparison tests daily:

**File: `tests/run_daily_tests.sh`**
```bash
#!/bin/bash
# Run at 2 AM daily

cd /path/to/AllOurPhotos/tests

# Start both backends in test mode
./start_test_backends.sh

# Run test suite
pytest backend_comparison/ -v --html=report_$(date +%Y%m%d).html

# Compare performance
./performance/compare_performance.sh

# Send results email
python send_test_report.py

# Stop backends
./stop_test_backends.sh
```
