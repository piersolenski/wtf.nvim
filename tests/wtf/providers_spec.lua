local client = require("wtf.ai.client")
local config = require("wtf.config")
local providers = require("wtf.ai.providers")

-- NOTE: In order for this integration test to pass, the following must be true:
-- 1. All environment variables are set correctly.
-- 2. All providers that require a balance are funded.
-- 3. All providers that run locally should be running.

describe("Providers", function()
  for provider_name, provider in pairs(providers) do
    describe(provider.formatted_name, function()
      local skip_reason = nil

      -- Skip if TEST_PROVIDER is set and doesn't match this provider
      local test_provider = os.getenv("TEST_PROVIDER")
      if test_provider and test_provider ~= provider_name then
        skip_reason = string.format("Only testing %s provider", test_provider)
      end

      -- For providers with API keys
      if provider.api_key and not skip_reason then
        local success, result = pcall(provider.api_key)
        if not success then
          local env_var = result:match("Missing environment variable: (.+)")
          if env_var then
            skip_reason = string.format("Requires %s environment variable to be set", env_var)
          end
        end
      end

      -- Special case for Ollama which requires a model ID set in the Makefile
      if provider_name == "ollama" and not skip_reason then
        if not os.getenv("OLLAMA_MODEL_ID") then
          skip_reason = "Requires OLLAMA_MODEL_ID environment variable to be set"
        end
      end

      -- Define tests once - they handle skipping internally
      it("handles success", function()
        if skip_reason then
          pending(skip_reason)
          return
        end

        config.setup({
          provider = provider_name,
        })

        local res, err = client("You are a testing helper.", "Say 'this is a test'", 0.5)
        assert.is_nil(err)
        assert.is_string(res)
        assert.not_nil(res)
      end)

      if provider.api_key then
        it("handles an incorrect api key", function()
          if skip_reason then
            pending(skip_reason)
            return
          end

          config.setup({
            provider = provider_name,
            providers = {
              [provider_name] = {
                api_key = "this-is-a-bunk-api-key",
              },
            },
          })

          local res, err = client("You are a testing helper.", "Say 'this is a test'", 0.5)
          assert.is_nil(res)
          assert.is_string(err)
          assert.not_nil(err)
        end)
      end

      it("handles an incorrect model", function()
        if skip_reason then
          pending(skip_reason)
          return
        end

        config.setup({
          provider = provider_name,
          providers = {
            [provider_name] = {
              model = "this-model-does-not-exist",
            },
          },
        })

        local _, err = client("You are a testing helper.", "Say 'this is a test'", 0.5)
        assert.is_true(err == nil or type(err) == "string")
      end)
    end)
  end
end)
