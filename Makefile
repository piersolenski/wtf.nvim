TESTS_INIT=tests/minimal_init.lua
TESTS_DIR=tests

.PHONY: test lint

format:
	stylua .

lint:
	@luacheck lua

test:
	@echo "Starting Ollama with tinyllama model..." && \
	ollama run tinyllama > /dev/null 2>&1 & \
	OLLAMA_PID=$$! && \
	echo "Ollama started with PID $$OLLAMA_PID" && \
	sleep 5 && \
	echo "Running tests..." && \
	(nvim \
		--headless \
		--noplugin \
		-u ${TESTS_INIT} \
		-c "PlenaryBustedDirectory ${TESTS_DIR} { minimal_init = '${TESTS_INIT}' }" && \
	echo "Tests completed successfully") || TEST_FAILED=1; \
	echo "Stopping Ollama (PID $$OLLAMA_PID)..."; \
	kill $$OLLAMA_PID 2>/dev/null || true; \
	if [ "$$TEST_FAILED" = "1" ]; then exit 1; fi
