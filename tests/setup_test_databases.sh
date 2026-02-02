#!/bin/bash
# Setup test databases for backend comparison testing
# This script copies allourphotos_asus to two test databases

set -e  # Exit on error

# Database configuration
SOURCE_DB="allourphotos_asus"
TEST_DB_PYTHON="allourphotos_test_python"
TEST_DB_NODE="allourphotos_test_node"

# MySQL credentials (customize these)
DB_HOST="localhost"
DB_USER="photos"
DB_PASS="photos00"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Test Database Setup Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Source database: $SOURCE_DB"
echo "Target databases:"
echo "  - $TEST_DB_PYTHON (for Python backend)"
echo "  - $TEST_DB_NODE (for Node backend)"
echo ""

# Confirm before proceeding
read -p "This will DROP and recreate the test databases. Continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Check if source database exists
echo -e "\n${YELLOW}Checking source database...${NC}"
if ! mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -e "USE $SOURCE_DB" 2>/dev/null; then
    echo -e "${RED}ERROR: Source database '$SOURCE_DB' does not exist!${NC}"
    exit 1
fi

# Get record counts from source
echo -e "${GREEN}Source database statistics:${NC}"
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$SOURCE_DB" <<EOF
SELECT 'aopusers' as table_name, COUNT(*) as count FROM aopusers
UNION ALL SELECT 'aopsessions', COUNT(*) FROM aopsessions
UNION ALL SELECT 'aopalbums', COUNT(*) FROM aopalbums
UNION ALL SELECT 'aopsnaps', COUNT(*) FROM aopsnaps
UNION ALL SELECT 'aopalbum_items', COUNT(*) FROM aopalbum_items;
EOF

echo ""
read -p "Press Enter to continue with database copy..."

# Create temporary dump file
DUMP_FILE="/tmp/${SOURCE_DB}_dump_$(date +%Y%m%d_%H%M%S).sql"
echo -e "\n${YELLOW}Step 1: Dumping source database to $DUMP_FILE...${NC}"
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    "$SOURCE_DB" > "$DUMP_FILE"

DUMP_SIZE=$(du -h "$DUMP_FILE" | cut -f1)
echo -e "${GREEN}✓ Dump complete (${DUMP_SIZE})${NC}"

# Function to create and populate a test database
create_test_db() {
    local DB_NAME=$1
    echo -e "\n${YELLOW}Step 2: Creating test database '$DB_NAME'...${NC}"

    # Drop if exists and create new
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" <<EOF
DROP DATABASE IF EXISTS $DB_NAME;
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
EOF

    echo -e "${GREEN}✓ Database created${NC}"

    echo -e "${YELLOW}Step 3: Importing data into '$DB_NAME'...${NC}"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" < "$DUMP_FILE"
    echo -e "${GREEN}✓ Data imported${NC}"

    # Verify record counts
    echo -e "${YELLOW}Verifying record counts in '$DB_NAME':${NC}"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" <<EOF
SELECT 'aopusers' as table_name, COUNT(*) as count FROM aopusers
UNION ALL SELECT 'aopsessions', COUNT(*) FROM aopsessions
UNION ALL SELECT 'aopalbums', COUNT(*) FROM aopalbums
UNION ALL SELECT 'aopsnaps', COUNT(*) FROM aopsnaps
UNION ALL SELECT 'aopalbum_items', COUNT(*) FROM aopalbum_items;
EOF
}

# Create both test databases
create_test_db "$TEST_DB_PYTHON"
echo ""
create_test_db "$TEST_DB_NODE"

# Clean up dump file
echo -e "\n${YELLOW}Cleaning up temporary dump file...${NC}"
rm "$DUMP_FILE"
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Final summary
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Test databases created:"
echo "  ✓ $TEST_DB_PYTHON"
echo "  ✓ $TEST_DB_NODE"
echo ""
echo "Next steps:"
echo "  1. Update pyserver/config.json to use '$TEST_DB_PYTHON'"
echo "  2. Update backend/.env to use '$TEST_DB_NODE'"
echo "  3. Ensure both backends point to the same photos directory"
echo "  4. Start running comparison tests"
echo ""
echo -e "${YELLOW}Note: These test databases are independent copies.${NC}"
echo -e "${YELLOW}Changes to one will NOT affect the other or the source database.${NC}"
