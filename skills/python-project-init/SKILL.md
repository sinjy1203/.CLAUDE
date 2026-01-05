---
name: python-project-init
description: "Initialize a new Python project with standardized development environment setup including UV virtual environment (Python 3.12), Ruff linter/formatter, Black formatter, pre-commit hooks, and VSCode configuration. Use this skill when the user requests to: (1) Start a new Python project with UV, (2) Set up Python development environment, (3) Add code quality tools (Ruff, Black, pre-commit) to a Python project, (4) Configure VSCode for Python development with standardized settings, or (5) Create pyproject.toml with Ruff and Black configuration."
---

# Python Project Init

## Overview

This skill automates the setup of a standardized Python development environment with modern tooling. It creates a Python 3.12 virtual environment using UV, configures code quality tools (Ruff, Black, pre-commit), and sets up VSCode for optimal Python development.

## Quick Start

### Option 1: Automated Setup (Recommended)

Run the setup script from the project root directory:

```bash
bash /path/to/skill/scripts/setup.sh
```

This will automatically:
1. Create a `.venv/` with Python 3.12
2. Create `.vscode/settings.json` (if not exists)
3. Create `.pre-commit-config.yaml` (if not exists)
4. Install dependencies from `pyproject.toml` (if exists)
5. Install pre-commit hooks

### Option 2: Manual Setup

Follow the steps below if you need more control over the setup process.

## Step-by-Step Manual Setup

### Step 1: Create Virtual Environment

Create a Python 3.12 virtual environment using UV:

```bash
uv venv --python 3.12
```

This creates a `.venv/` directory in the project root.

### Step 2: Create pyproject.toml

Create `pyproject.toml` with the configuration below. Replace placeholders:
- `{{PROJECT_NAME}}`: Package name (e.g., "my-project")
- `{{PROJECT_DESCRIPTION}}`: Brief description
- `{{PACKAGE_NAME}}`: Python package name for imports (e.g., "my_project")

See [assets/pyproject.toml.template](assets/pyproject.toml.template) for the full template with:
- Line length: 120 characters
- Target Python version: 3.12
- Ruff rules: E, W, F, I, N, UP, B, C4, SIM
- Black configuration matching Ruff
- Dev dependencies: pytest, black, ruff, pre-commit

**Key configuration highlights:**

```toml
[tool.ruff]
line-length = 120
target-version = "py312"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E501"]  # line too long (handled by formatter)

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]  # Allow unused imports

[tool.black]
line-length = 120
target-version = ["py312"]
```

### Step 3: Create VSCode Settings

Create `.vscode/settings.json` with the configuration from [assets/vscode_settings.json.template](assets/vscode_settings.json.template).

**Key settings:**
- Ruff extension enabled with `filesystemFirst` preference (reads pyproject.toml)
- Format on save with Ruff
- Auto-fix and organize imports on save
- 120-character ruler and word wrap

**Important:** Install the Ruff VSCode extension (`charliermarsh.ruff`) for these settings to work.

### Step 4: Create Pre-commit Configuration

Create `.pre-commit-config.yaml` with the configuration from [assets/pre-commit-config.yaml.template](assets/pre-commit-config.yaml.template).

**Includes hooks for:**
- Ruff (linting and formatting)
- Black (formatting)
- Standard checks (trailing whitespace, YAML/TOML/JSON validation, etc.)

### Step 5: Install Dependencies and Hooks

```bash
# Install dependencies (including dev dependencies)
uv sync --extra dev

# Install pre-commit hooks
uv run pre-commit install
```

For UV workspace (monorepo) projects, use:

```bash
# Install all workspace packages
uv sync --all-packages --extra dev
```

### Step 6: Verify Setup

1. Activate the virtual environment:
   ```bash
   source .venv/bin/activate
   ```

2. Test Ruff:
   ```bash
   uv run ruff check .
   uv run ruff format .
   ```

3. Test pre-commit:
   ```bash
   uv run pre-commit run --all-files
   ```

4. Open the project in VSCode and verify:
   - Python interpreter is set to `.venv/bin/python`
   - Ruff extension is active
   - Saving a Python file triggers auto-formatting

## Workflow for Different Scenarios

### New Project from Scratch

1. Create project directory: `mkdir my-project && cd my-project`
2. Run automated setup: `bash /path/to/skill/scripts/setup.sh`
3. Manually create and edit `pyproject.toml` using the template
4. Run `uv sync --extra dev`
5. Run `uv run pre-commit install`

### Adding to Existing Project

1. Navigate to project root
2. Run automated setup: `bash /path/to/skill/scripts/setup.sh`
3. If `pyproject.toml` exists, merge the Ruff/Black settings from the template
4. Install dependencies: `uv sync --extra dev`
5. Install hooks: `uv run pre-commit install`

### Workspace/Monorepo Project

For UV workspace projects (multiple packages in `apps/` or similar):

1. Run setup from workspace root
2. Create individual `pyproject.toml` in each app if needed
3. Use `uv sync --all-packages --extra dev` instead of `uv sync`
4. VSCode settings apply to the entire workspace

## Common Commands

```bash
# Format all files
uv run ruff format .

# Check and auto-fix linting issues
uv run ruff check --fix .

# Run pre-commit on all files
uv run pre-commit run --all-files

# Sync dependencies
uv sync --extra dev
uv sync --all-packages --extra dev  # for workspace projects
```

## Troubleshooting

**Ruff not working in VSCode:**
- Ensure Ruff extension (`charliermarsh.ruff`) is installed
- Check that `ruff.configurationPreference` is set to `"filesystemFirst"` in settings.json
- Restart VSCode after installing the extension

**Pre-commit hooks not running:**
- Ensure you ran `uv run pre-commit install`
- Check that `.pre-commit-config.yaml` exists in project root
- Try running manually: `uv run pre-commit run --all-files`

**UV command not found:**
- Install UV: https://github.com/astral-sh/uv
- Ensure UV is in your PATH

## Resources

This skill includes the following bundled resources:

### assets/
Template files for project configuration:
- `pyproject.toml.template` - Complete pyproject.toml with Ruff, Black, and pre-commit settings
- `vscode_settings.json.template` - VSCode configuration for Python development
- `pre-commit-config.yaml.template` - Pre-commit hooks configuration

### scripts/
- `setup.sh` - Automated setup script that creates virtual environment, copies templates, and installs dependencies
