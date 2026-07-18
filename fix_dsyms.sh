#!/bin/sh
# Script to copy missing dSYMs for SPM binary dependencies (e.g. Firebase)
# This addresses the "Missing dSYM" error during TestFlight upload for SPM binary frameworks.

if [ "$ACTION" = "install" ]; then
    echo "Searching for missing dSYMs in SPM checkouts..."
    # Locate the SPM checkouts directory relative to the build directory
    CHECKOUTS_DIR="${BUILD_DIR%Build/*}SourcePackages/checkouts"
    if [ -d "$CHECKOUTS_DIR" ]; then
        echo "Checking $CHECKOUTS_DIR"
        find "$CHECKOUTS_DIR" -name "*.dSYM" -exec cp -R {} "${DWARF_DSYM_FOLDER_PATH}" \;
    fi
    
    # Also check the artifacts directory (used by some SPM versions/configs)
    ARTIFACTS_DIR="${BUILD_DIR%Build/*}SourcePackages/artifacts"
    if [ -d "$ARTIFACTS_DIR" ]; then
        echo "Checking $ARTIFACTS_DIR"
        find "$ARTIFACTS_DIR" -name "*.dSYM" -exec cp -R {} "${DWARF_DSYM_FOLDER_PATH}" \;
    fi
    
    echo "dSYM copy process finished."
fi
