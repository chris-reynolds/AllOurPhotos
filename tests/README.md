# AllOurPhotos Test Suite

This directory contains test scripts and utilities for backend migration testing.

## Setup Test Databases

### Windows (PowerShell)
```powershell
cd tests
.\setup_test_databases.ps1
```

### Linux/Mac/WSL (Bash)
```bash
cd tests
chmod +x setup_test_databases.sh
./setup_test_databases.sh
```

### What the script does:
1. Dumps the source database (`allourphotos_asus`)
2. Creates two new test databases:
   - `allourphotos_test_python` - for Python FastAPI backend testing
   - `allourphotos_test_node` - for Node/Express backend testing
3. Imports the dump into both test databases
4. Verifies record counts match the source
5. Cleans up temporary files

### Configuration
Edit the script to customize database credentials:
```bash
# In setup_test_databases.sh or .ps1
DB_HOST="localhost"
DB_USER="photos"
DB_PASS="photos00"
```

### After Setup
1. **Update Python backend config:**
   ```json
   // pyserver/config.json
   {
     "db": {
       "database": "allourphotos_test_python",
       ...
     }
   }
   ```

2. **Update Node backend config:**
   ```bash
   # backend/.env (or create .env.test)
   DB_NAME=allourphotos_test_node
   ```

3. **Ensure both use same photos directory:**
   - Python: `"photos": "c:/data/photos/test/"` in config.json
   - Node: `PHOTOS_DIR=c:/data/photos/test/` in .env

## Directory Structure

```
tests/
├── README.md                      # This file
├── setup_test_databases.sh        # Bash version of setup script
├── setup_test_databases.ps1       # PowerShell version of setup script
├── fixtures/                      # Test data fixtures (to be created)
├── backend_comparison/            # Backend comparison tests (to be created)
│   ├── test_endpoints.py
│   ├── test_crud.py
│   └── test_images.py
├── performance/                   # Performance testing (to be created)
│   ├── artillery_config.yml
│   └── compare_performance.sh
└── verification/                  # Data verification tools (to be created)
    └── db_diff.py
```

## Next Steps

Follow the [Backend Migration Testing Plan](../aop_backend_plan.md) to:
1. Set up test infrastructure (pytest, artillery, etc.)
2. Create comparison test scripts
3. Run functional equivalence tests
4. Perform load testing
5. Validate data consistency

## Resetting Test Databases

To reset the test databases to match the current production state, simply re-run the setup script. It will drop and recreate the test databases with fresh data.

## Notes

- Test databases are **independent copies** - changes don't affect production
- Both test databases start with identical data
- You can run tests against both backends simultaneously
- Don't commit database dumps to git (they're in .gitignore)
