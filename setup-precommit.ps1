# Pre-commit setup script for Windows
# This script installs pre-commit and sets up the hooks

Write-Host "Setting up pre-commit for Hugo blog..." -ForegroundColor Green

# Check if Python is installed
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Found Python: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "Python is not installed or not in PATH. Please install Python first." -ForegroundColor Red
    exit 1
}

# Check if pip is available
try {
    pip --version | Out-Null
    Write-Host "pip is available" -ForegroundColor Green
} catch {
    Write-Host "pip is not available. Please ensure pip is installed." -ForegroundColor Red
    exit 1
}

# Install pre-commit
Write-Host "Installing pre-commit..." -ForegroundColor Yellow
pip install pre-commit

# Install the git hooks
Write-Host "Installing pre-commit hooks..." -ForegroundColor Yellow
pre-commit install

# Run pre-commit on all files to test the setup
Write-Host "Running pre-commit on all files..." -ForegroundColor Yellow
pre-commit run --all-files

Write-Host "Pre-commit setup complete!" -ForegroundColor Green
Write-Host "Pre-commit will now run automatically on git commits." -ForegroundColor Green
