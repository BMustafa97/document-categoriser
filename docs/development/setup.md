# Project Setup Guide

> **Status:** ⏳ Template Ready - Update as you set up your development environment

## 🚀 Quick Start

### Prerequisites Checklist
- [ ] **Python 3.8+** installed
- [ ] **AWS CLI** installed and configured
- [ ] **Docker** installed
- [ ] **Git** installed
- [ ] **AWS Account** with appropriate permissions

## 🔧 Development Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/BMustafa97/document-categoriser.git
cd document-categoriser
```

### 2. Python Environment Setup

#### Option A: Using venv
```bash
python3 -m venv venv
source venv/bin/activate  # On macOS/Linux
# or
venv\Scripts\activate     # On Windows

pip install -r requirements.txt
```

#### Option B: Using conda
```bash
conda create -n document-categoriser python=3.9
conda activate document-categoriser
pip install -r requirements.txt
```

### 3. Environment Variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

#### Required Environment Variables
```bash
# AWS Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# S3 Configuration
S3_BUCKET_NAME=your-bucket-name

# SES Configuration
SES_SENDER_EMAIL=your-verified-email@domain.com

# Application Configuration
FLASK_ENV=development
FLASK_DEBUG=True
SECRET_KEY=your-secret-key

# Virus Scanning (if using ClamAV)
CLAMAV_ENABLED=false
CLAMAV_HOST=localhost
CLAMAV_PORT=3310
```

## 🛠️ Dependencies & Requirements

### Python Dependencies
Create `requirements.txt` as you add dependencies:

```txt
# Flask Framework
Flask==2.3.2
Flask-WTF==1.1.1

# AWS SDKs
boto3==1.28.25
botocore==1.31.25

# File Processing
python-magic==0.4.27
PyPDF2==3.0.1

# Virus Scanning (if using pyclamd)
pyclamd==0.4.0

# Environment Management
python-dotenv==1.0.0

# Testing
pytest==7.4.0
pytest-flask==1.2.0

# Development
black==23.7.0
flake8==6.0.0
```

### System Dependencies (macOS)
```bash
# Install required system packages
brew install libmagic
brew install clamav  # If using ClamAV locally
```

### System Dependencies (Ubuntu/Debian)
```bash
# Install required system packages
sudo apt-get update
sudo apt-get install -y \
    python3-dev \
    libmagic1 \
    clamav \
    clamav-daemon
```

## 🏗️ Project Structure Setup

### Create Initial Directory Structure
```bash
mkdir -p src/{config,services,utils,templates,static/{css,js}}
mkdir -p tests/{unit,integration}
mkdir -p logs
touch src/__init__.py
touch src/app.py
touch src/config/__init__.py
touch src/services/__init__.py
touch src/utils/__init__.py
```

### Expected Project Structure
```
document-categoriser/
├── src/
│   ├── __init__.py
│   ├── app.py                 # Main Flask application
│   ├── config/
│   │   ├── __init__.py
│   │   └── settings.py        # Configuration management
│   ├── services/
│   │   ├── __init__.py
│   │   ├── s3_service.py      # S3 operations
│   │   ├── textract_service.py # Textract integration
│   │   ├── comprehend_service.py # Comprehend integration
│   │   ├── ses_service.py     # SES email service
│   │   └── virus_scanner.py   # Virus scanning service
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── file_handler.py    # File utilities
│   │   └── validators.py      # Input validation
│   ├── templates/
│   │   ├── base.html          # Base template
│   │   ├── index.html         # Upload interface
│   │   └── results.html       # Results display
│   └── static/
│       ├── css/
│       │   └── styles.css     # Custom styles
│       └── js/
│           └── app.js         # Frontend JavaScript
├── tests/
│   ├── unit/                  # Unit tests
│   ├── integration/           # Integration tests
│   └── conftest.py           # Test configuration
├── logs/                      # Application logs
├── requirements.txt
├── .env.example
├── .gitignore
├── Dockerfile
└── docker-compose.yml
```

## 🔐 AWS Configuration

### 1. AWS CLI Setup
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

### 2. Verify AWS Access
```bash
# Test AWS connectivity
aws sts get-caller-identity
aws s3 ls  # Should list your S3 buckets
```

### 3. Required AWS Permissions
Ensure your AWS user/role has permissions for:
- [ ] S3: ListBucket, GetObject, PutObject
- [ ] Textract: DetectDocumentText, StartDocumentTextDetection
- [ ] Comprehend: DetectDominantLanguage, DetectEntities
- [ ] SES: SendEmail, SendRawEmail
- [ ] ECR: GetAuthorizationToken, BatchCheckLayerAvailability
- [ ] ECS/Fargate: CreateService, UpdateService, DescribeServices

## 🧪 Testing Setup

### Test Framework Configuration
Create `tests/conftest.py`:
```python
import pytest
import os
import sys

# Add src to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    from app import app
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client
```

### Run Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src

# Run specific test file
pytest tests/unit/test_file_handler.py
```

## 🐳 Docker Setup (Local Development)

### Create docker-compose.yml
```yaml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
    volumes:
      - .:/app
      - /app/venv  # Exclude virtual environment
    depends_on:
      - localstack  # For local AWS services testing

  localstack:
    image: localstack/localstack
    ports:
      - "4566:4566"
    environment:
      - SERVICES=s3,ses
    volumes:
      - /tmp/localstack:/tmp/localstack
      - /var/run/docker.sock:/var/run/docker.sock
```

### Local Development Commands
```bash
# Build and run with docker-compose
docker-compose up --build

# Run in detached mode
docker-compose up -d

# View logs
docker-compose logs -f app

# Stop services
docker-compose down
```

## ✅ Verification Steps

### 1. Python Environment
```bash
python --version  # Should show Python 3.8+
pip list          # Should show installed packages
```

### 2. AWS Configuration
```bash
aws sts get-caller-identity  # Should show your AWS account info
```

### 3. Flask Application
```bash
cd src
python app.py    # Should start Flask development server
```

### 4. Basic Functionality Test
- [ ] Flask app starts without errors
- [ ] Upload form loads correctly
- [ ] AWS services are accessible
- [ ] Environment variables are loaded

## 🚨 Common Issues & Solutions

### Issue: AWS Credentials Not Found
**Solution:** Ensure AWS CLI is configured or environment variables are set correctly.

### Issue: Python Module Import Errors
**Solution:** Verify virtual environment is activated and packages are installed.

### Issue: Port Already in Use
**Solution:** Change Flask port in configuration or kill existing processes.

### Issue: File Permission Errors
**Solution:** Check file permissions and ensure proper ownership.

---

**📝 Setup Notes:**
[Document any specific setup issues or solutions you encounter]

- [DATE] - [Setup note or issue resolution]
- [DATE] - [Setup note or issue resolution]