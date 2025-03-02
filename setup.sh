#!/bin/bash

echo "Setting up CoWriter development environment..."

# Check for required tools
command -v node >/dev/null 2>&1 || { echo "Node.js is required but not installed. Aborting." >&2; exit 1; }
command -v npm >/dev/null 2>&1 || { echo "npm is required but not installed. Aborting." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Python 3 is required but not installed. Aborting." >&2; exit 1; }
command -v poetry >/dev/null 2>&1 || { echo "Poetry is required but not installed. Aborting." >&2; exit 1; }

# Create necessary directories
mkdir -p backend
mkdir -p co_writer

# Frontend setup
echo "Setting up frontend..."
cd co_writer
echo "Installing frontend dependencies..."
# Use legacy-peer-deps as a fallback if the first attempt fails
npm install || npm install --legacy-peer-deps
echo "Installing and configuring frontend linting tools..."
npm run lint || true  # Don't fail if there are linting errors
npx prettier --write . || true  # Don't fail if there are formatting errors

# Backend setup
echo "Setting up backend..."
cd ../backend
echo "Regenerating poetry lock file..."
poetry lock
echo "Installing backend dependencies..."
poetry install

# Install pre-commit hooks
echo "Setting up pre-commit hooks..."
mkdir -p ../.git/hooks
cat > ../.git/hooks/pre-commit << 'EOF'
#!/bin/bash

# Frontend checks
cd co_writer
echo "Running frontend checks..."
npm run lint || exit 1
npm run format:check || exit 1
npm run type-check || exit 1

# Backend checks
cd ../backend
echo "Running backend checks..."
poetry run black . --check || exit 1
poetry run isort . --check-only || exit 1
poetry run flake8 || exit 1
poetry run mypy app/ || exit 1
EOF

chmod +x ../.git/hooks/pre-commit

echo "Creating environment files..."
# Create backend environment file
if [ ! -f backend/.env ]; then
    echo "Creating backend/.env..."
    mkdir -p backend
    cat > backend/.env << 'EOF'
# Backend Environment Variables
OPENAI_API_KEY=your_api_key_here
MODEL_NAME=gpt-4-turbo-preview
DEBUG=False
ALLOWED_ORIGINS=http://localhost:3000  # Comma-separated list of allowed origins
EOF
    echo "Created backend/.env"
fi

# Create frontend environment file
if [ ! -f co_writer/.env ]; then
    echo "Creating co_writer/.env..."
    mkdir -p co_writer
    cat > co_writer/.env << 'EOF'
# Frontend Environment Variables
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF
    echo "Created co_writer/.env"
fi

echo "Setup complete! Please configure your environment variables in:"
echo "- backend/.env"
echo "- co_writer/.env"
echo ""
echo "Note: Some linting errors were found. You can fix them by running:"
echo "Frontend:"
echo "cd co_writer && npm run lint --fix"
echo "cd co_writer && npm run format"
echo ""
echo "To start the development servers:"
echo "1. Frontend: cd co_writer && npm run dev"
echo "2. Backend: cd backend && poetry run uvicorn app.main:app --reload"
echo ""
echo "Available commands:"
echo "Frontend:"
echo "- npm run dev: Start development server"
echo "- npm run lint: Run ESLint"
echo "- npm run format: Run Prettier"
echo "- npm run type-check: Run TypeScript checks"
echo ""
echo "Backend:"
echo "- poetry run black .: Format code"
echo "- poetry run isort .: Sort imports"
echo "- poetry run flake8: Run linter"
echo "- poetry run mypy app/: Run type checker" 