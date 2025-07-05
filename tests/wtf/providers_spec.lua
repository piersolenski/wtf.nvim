local client = require("wtf.ai.client")
local config = require("wtf.config")
local providers = require("wtf.ai.providers")

-- NOTE: In order for this integration test to pass, the following must be true:
-- 1. All environment variables are set correctly.
-- 2. All providers that require a balance are funded.
-- 3. All providers that run locally should be running.

describe("Providers", function()
  if os.getenv("GITHUB_ACTIONS") then
    pending("Skipped in GitHub CI")
    return
  end

  for provider_name, provider in pairs(providers) do
    describe(provider.formatted_name, function()
      it("handles success", function()
        config.setup({
          provider = provider_name,
        })

        local res, err = client("You are a testing helper.", "Say 'this is a test'")
        assert.is_nil(err)
        assert.is_string(res)
        assert.not_nil(res)
      end)

      if provider.api_key then
        it("handles an incorrect api key", function()
          config.setup({
            provider = provider_name,
            providers = {
              [provider_name] = {
                api_key = "this-is-a-bunk-api-key",
              },
            },
          })

          local res, err = client("You are a testing helper.", "Say 'this is a test'")
          assert.is_nil(res)
          assert.is_string(err)
          assert.not_nil(err)
        end)
      end

      it("handles an incorrect model", function()
        config.setup({
          provider = provider_name,
          providers = {
            [provider_name] = {
              model = "this-model-does-not-exist",
            },
          },
        })

        local _, err = client("You are a testing helper.", "Say 'this is a test'")
        assert.is_true(err == nil or type(err) == "string")
      end)
    end)
  end
end)
