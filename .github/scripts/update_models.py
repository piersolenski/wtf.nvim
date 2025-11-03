#!/usr/bin/env python3
"""Check and update AI provider models."""
import os
import re
import subprocess
import requests

PROVIDERS = {
    "openai": {
        "file": "lua/wtf/ai/providers/openai.lua",
        "api": "https://api.openai.com/v1/models",
        "auth": lambda key: {"Authorization": f"Bearer {key}"},
    },
    "anthropic": {
        "file": "lua/wtf/ai/providers/anthropic.lua",
        "api": "https://api.anthropic.com/v1/models",
        "auth": lambda key: {"x-api-key": key, "anthropic-version": "2023-06-01"},
    },
    "gemini": {
        "file": "lua/wtf/ai/providers/gemini.lua",
        "api": "https://generativelanguage.googleapis.com/v1beta/models",
        "auth": lambda _: {},
        "url": lambda api, key: f"{api}?key={key}",
    },
    "deepseek": {
        "file": "lua/wtf/ai/providers/deepseek.lua",
        "api": "https://api.deepseek.com/v1/models",
        "auth": lambda key: {"Authorization": f"Bearer {key}"},
    },
    "grok": {
        "file": "lua/wtf/ai/providers/grok.lua",
        "api": "https://api.x.ai/v1/models",
        "auth": lambda key: {"Authorization": f"Bearer {key}"},
    },
}


def get_current_model(file_path):
    """Extract model_id from Lua file."""
    with open(file_path) as f:
        match = re.search(r'model_id\s*=\s*"([^"]+)"', f.read())
        return match.group(1) if match else None


def ask_claude(provider, current_model, provider_api_key, anthropic_key):
    """Use Claude to research and recommend best model."""
    config = PROVIDERS[provider]
    url = config.get("url", lambda api, _: api)(config["api"], provider_api_key)

    resp = requests.get(url, headers=config["auth"](provider_api_key), timeout=10)
    resp.raise_for_status()

    data = resp.json()
    models = [m.get("id") or m["name"].split("/")[-1] for m in data.get("data", data.get("models", []))]

    prompt = f"""Current {provider} model: {current_model}

Available models: {", ".join(models[:30])}

Recommend the BEST production-ready model for code debugging/diagnostics. Reply with ONLY the model ID, or "KEEP" if current is best."""

    resp = requests.post(
        "https://api.anthropic.com/v1/messages",
        headers={"x-api-key": anthropic_key, "anthropic-version": "2023-06-01"},
        json={"model": "claude-sonnet-4-5-20250929", "max_tokens": 100, "messages": [{"role": "user", "content": prompt}]},
        timeout=30
    )
    resp.raise_for_status()

    result = resp.json()["content"][0]["text"].strip()
    return None if result == "KEEP" else result


def update_model(file_path, old, new):
    """Update model in file."""
    with open(file_path) as f:
        content = f.read()
    with open(file_path, "w") as f:
        f.write(re.sub(f'model_id = "{re.escape(old)}"', f'model_id = "{new}"', content))


def create_pr(provider, old, new):
    """Create PR for model update."""
    branch = f"update-{provider}-model"
    subprocess.run(["git", "checkout", "-b", branch], check=True)
    subprocess.run(["git", "add", PROVIDERS[provider]["file"]], check=True)
    subprocess.run(["git", "commit", "-m", f"chore: update {provider} model to {new}"], check=True)
    subprocess.run(["git", "push", "-u", "origin", branch], check=True)
    subprocess.run([
        "gh", "pr", "create",
        "--title", f"chore: update {provider.title()} model to latest version",
        "--body", f"Updates {provider} model from `{old}` to `{new}`\n\n🤖 Auto-generated"
    ], check=True)


def main():
    anthropic_key = os.getenv("ANTHROPIC_API_KEY")
    if not anthropic_key:
        print("✗ ANTHROPIC_API_KEY required for Claude decision-making")
        return

    for provider, config in PROVIDERS.items():
        api_key = os.getenv(f"{provider.upper()}_API_KEY")
        if not api_key:
            print(f"⊘ Skipping {provider} (no API key)")
            continue

        try:
            current = get_current_model(config["file"])
            print(f"Checking {provider}... (current: {current})")

            recommended = ask_claude(provider, current, api_key, anthropic_key)

            if recommended and recommended != current:
                print(f"✓ {provider}: {current} → {recommended}")
                update_model(config["file"], current, recommended)
                create_pr(provider, current, recommended)
            else:
                print(f"✓ {provider}: {current} (up to date)")
        except Exception as e:
            print(f"✗ {provider}: {e}")


if __name__ == "__main__":
    main()
