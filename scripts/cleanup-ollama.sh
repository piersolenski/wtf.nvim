#!/bin/bash

# Cleanup Ollama after testing

if [ -f /tmp/ollama.pid ]; then
    OLLAMA_PID=$(cat /tmp/ollama.pid)
    if [ -n "$OLLAMA_PID" ]; then
        echo "Stopping Ollama (PID $OLLAMA_PID)..."
        kill "$OLLAMA_PID" 2>/dev/null || true
        rm -f /tmp/ollama.pid
    fi
else
    echo "No Ollama PID found, nothing to clean up"
fi