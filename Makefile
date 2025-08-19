TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests
OLLAMA_MODEL_ID?=tinyllama

.PHONY: test lint

format:
	stylua .

lint:
	@luacheck lua

test:
	@if ! which ollama >/dev/null 2>&1; then \
		echo "Ollama not found. Installing Ollama..."; \
		if [ "$$(uname)" = "Darwin" ]; then \
			if command -v brew >/dev/null 2>&1; then \
				brew install ollama; \
			else \
				echo "Please install Ollama manually from https://ollama.ai"; \
				exit 1; \
			fi; \
		elif [ "$$(uname)" = "Linux" ]; then \
			curl -fsSL https://ollama.ai/install.sh | sh; \
		else \
			echo "Unsupported OS. Please install Ollama manually from https://ollama.ai"; \
			exit 1; \
		fi; \
	fi; \
	echo "Starting Ollama server..." && \
	ollama serve > /dev/null 2>&1 & \
	OLLAMA_PID=$$! && \
	echo "Ollama server started with PID $$OLLAMA_PID" && \
	sleep 2 && \
	echo "Pulling ${OLLAMA_MODEL_ID} model if needed..." && \
	ollama pull ${OLLAMA_MODEL_ID} && \
	echo "Model ${OLLAMA_MODEL_ID} ready" && \
	echo "Running tests..." && \
	(OLLAMA_MODEL_ID=${OLLAMA_MODEL_ID} nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }" && \
	echo "Tests completed successfully") || TEST_FAILED=1; \
	echo "Stopping Ollama (PID $$OLLAMA_PID)..."; \
	kill $$OLLAMA_PID 2>/dev/null || true; \
	if [ "$$TEST_FAILED" = "1" ]; then exit 1; fi
