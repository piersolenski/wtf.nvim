TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests
OLLAMA_MODEL_ID?=tinyllama

.PHONY: test lint

format:
	stylua .

lint:
	@luacheck lua

# Will run tests using Ollama on systems that support installation in a Unix
# environment as well as cloud based models if their API key is available
test:
	@chmod +x scripts/setup-ollama.sh scripts/cleanup-ollama.sh
	@if ./scripts/setup-ollama.sh; then \
		echo "Ollama ready"; \
	else \
		echo "Ollama not available, skipping Ollama tests"; \
	fi
	@echo "Running tests..."
	@(OLLAMA_MODEL_ID=${OLLAMA_MODEL_ID} nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }" && \
	echo "Tests completed successfully") || TEST_FAILED=1
	@./scripts/cleanup-ollama.sh || true
	@if [ "$$TEST_FAILED" = "1" ]; then exit 1; fi
