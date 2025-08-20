CI Build Farm Portal (React)

Quick start (local):
1. cp .env.example .env.local and edit REACT_APP_API_BASE if needed
2. npm ci
3. npm start

Build for production:
1. npm ci
2. npm run build
3. Upload `build/` to your chosen static host (S3 bucket, Netlify, etc.)

This app expects the API base URL to be available as the environment variable:
REACT_APP_API_BASE (e.g. https://abc123.execute-api.us-east-1.amazonaws.com)

The "Run tests" button sends { repo, branch, agents } to POST ${REACT_APP_API_BASE}/run
