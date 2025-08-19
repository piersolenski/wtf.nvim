#!/bin/bash

# Setup Ollama for testing
# Returns: 0 if Ollama is ready, 1 if not available (but tests should still run)

set -e

OLLAMA_MODEL="${OLLAMA_MODEL_ID:-tinyllama}"

check_ollama() {
    command -v ollama >/dev/null 2>&1
}

install_ollama() {
    echo "Ollama not found. Attempting to install..."
    echo "Detected OS: $(uname -s)"
    
    case "$(uname -s)" in
        Darwin)
            if command -v brew >/dev/null 2>&1; then
                echo "Installing Ollama via Homebrew..."
                brew install ollama
                return 0
            else
                echo "Homebrew not found. Skipping Ollama installation."
                return 1
            fi
            ;;
        Linux)
            echo "Installing Ollama via official script..."
            curl -fsSL https://ollama.ai/install.sh | sh
            return 0
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "Windows detected. Ollama auto-install not supported."
            echo "Ollama tests will be skipped."
            return 1
            ;;
        *)
            echo "Unsupported OS: $(uname -s)"
            echo "Ollama tests will be skipped."
            return 1
            ;;
    esac
}

start_ollama() {
    echo "Starting Ollama server..."
    ollama serve >/dev/null 2>&1 &
    OLLAMA_PID=$!
    echo "Ollama server started with PID $OLLAMA_PID"
    
    # Wait for server to be ready
    sleep 2
    
    echo "Pulling $OLLAMA_MODEL model if needed..."
    if ollama pull "$OLLAMA_MODEL"; then
        echo "Model $OLLAMA_MODEL ready"
        echo "$OLLAMA_PID" > /tmp/ollama.pid
        return 0
    else
        echo "Failed to pull model $OLLAMA_MODEL"
        kill $OLLAMA_PID 2>/dev/null || true
        return 1
    fi
}

# Main logic
if check_ollama; then
    echo "Ollama found"
elif install_ollama; then
    echo "Ollama installed successfully"
else
    echo "Ollama not available. Ollama tests will be skipped."
    exit 1
fi

if start_ollama; then
    echo "Ollama is ready for testing"
    exit 0
else
    echo "Failed to start Ollama. Ollama tests will be skipped."
    exit 1
fi