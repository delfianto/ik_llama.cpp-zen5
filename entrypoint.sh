#!/bin/bash

# Default values
HOST=${HOST:-0.0.0.0}
PORT=${PORT:-8080}
CTX_SIZE=${CTX_SIZE:-8192}
N_GPU_LAYERS=${N_GPU_LAYERS:--1}
THREADS=${THREADS:-$(nproc)}

# Base command
CMD=("/usr/local/bin/llama-server" "--host" "${HOST}" "--port" "${PORT}" "-c" "${CTX_SIZE}" "-ngl" "${N_GPU_LAYERS}" "-t" "${THREADS}")

# Check for main model
if [ -n "$MODEL_PATH" ]; then
    CMD+=("-m" "$MODEL_PATH")
else
    echo "ERROR: MODEL_PATH environment variable is required."
    exit 1
fi

# Check for MTP / Speculative draft model (Gemma 4 MTP support)
if [ -n "$MTP_MODEL_PATH" ]; then
    echo "MTP Draft Model detected. Enabling Multi-Token Prediction (draft-mtp)..."
    CMD+=("--spec-draft-model" "$MTP_MODEL_PATH")
    CMD+=("--spec-type" "draft-mtp")
    
    # Optional tuning for MTP
    if [ -n "$MTP_DRAFT_N" ]; then
        CMD+=("--spec-draft-n-max" "$MTP_DRAFT_N")
    else
        CMD+=("--spec-draft-n-max" "2") # Default conservative lookahead
    fi
fi

# Add any additional user-provided arguments
if [ -n "$EXTRA_ARGS" ]; then
    # We deliberately do not quote EXTRA_ARGS here so it splits into separate tokens
    for arg in $EXTRA_ARGS; do
        CMD+=("$arg")
    done
fi

echo "Starting llama-server with command: ${CMD[*]}"
exec "${CMD[@]}"
