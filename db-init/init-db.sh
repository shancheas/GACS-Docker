#!/bin/bash
# This script runs when MongoDB container first starts
# It creates the genieacs database and imports data from parameters folder

set -e

echo "=== Initializing GenieACS database ==="

# Create the database and collections
mongo <<EOF
use genieacs
db.createCollection("devices")
db.createCollection("presets")
db.createCollection("provisions")
db.createCollection("virtualParameters")
db.createCollection("config")
db.createCollection("permissions")
db.createCollection("users")
print("GenieACS database collections created successfully")
EOF

echo "=== Importing data from parameters folder ==="

# Path to parameters folder (mounted in docker-compose)
PARAMS_DIR="/docker-entrypoint-initdb.d/parameters"

# Import BSON files if they exist
if [ -d "$PARAMS_DIR" ]; then
    # Import config collection
    if [ -f "$PARAMS_DIR/config.bson" ]; then
        echo "Importing config collection..."
        mongorestore --db genieacs --collection config "$PARAMS_DIR/config.bson" --drop
        echo "Config collection imported successfully"
    fi

    # Import presets collection
    if [ -f "$PARAMS_DIR/presets.bson" ]; then
        echo "Importing presets collection..."
        mongorestore --db genieacs --collection presets "$PARAMS_DIR/presets.bson" --drop
        echo "Presets collection imported successfully"
    fi

    # Import provisions collection
    if [ -f "$PARAMS_DIR/provisions.bson" ]; then
        echo "Importing provisions collection..."
        mongorestore --db genieacs --collection provisions "$PARAMS_DIR/provisions.bson" --drop
        echo "Provisions collection imported successfully"
    fi

    # Import virtualParameters collection
    if [ -f "$PARAMS_DIR/virtualParameters.bson" ]; then
        echo "Importing virtualParameters collection..."
        mongorestore --db genieacs --collection virtualParameters "$PARAMS_DIR/virtualParameters.bson" --drop
        echo "VirtualParameters collection imported successfully"
    fi

    echo "=== All data imported successfully ==="
else
    echo "Parameters directory not found at $PARAMS_DIR, skipping import"
fi

echo "=== GenieACS database initialization complete ==="
