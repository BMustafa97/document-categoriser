# Local Development Environment

> **Status:** ⏳ Template Ready - Update as you set up local development

## 🖥️ Development Server Setup

### Flask Development Server
```bash
# Navigate to source directory
cd src

# Set Flask environment variables
export FLASK_APP=app.py
export FLASK_ENV=development
export FLASK_DEBUG=True

# Run the development server
flask run
# or
python app.py
```

### Development Server Configuration
- **Host:** `localhost` or `127.0.0.1`
- **Port:** `5000` (default)
- **Auto-reload:** Enabled in development mode
- **Debug mode:** Enabled for detailed error messages

## 🧪 Local AWS Services (LocalStack)

### Setup LocalStack for Testing
LocalStack provides local AWS service emulation for testing.

```bash
# Install LocalStack
pip install localstack

# Start LocalStack services
localstack start -d

# Configure AWS CLI to use LocalStack
export AWS_ENDPOINT_URL=http://localhost:4566
aws --endpoint-url=http://localhost:4566 s3 mb s3://test-bucket
```

### LocalStack Services Configuration
```bash
# Environment variables for local development
export AWS_ENDPOINT_URL=http://localhost:4566
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_REGION=us-east-1
```

## 📁 File Upload Testing

### Local File Upload Directory
```bash
# Create local upload directory for testing
mkdir -p uploads/temp
mkdir -p uploads/processed
mkdir -p uploads/failed
```

### Test Files
Create a test directory with sample documents:
```bash
mkdir -p test_files
# Add sample PDF, PNG, JPEG files for testing
```

## 🔧 Development Tools

### Code Formatting
```bash
# Install development dependencies
pip install black flake8 isort

# Format code
black src/
isort src/

# Lint code
flake8 src/
```

### Pre-commit Hooks (Optional)
```bash
# Install pre-commit
pip install pre-commit

# Create .pre-commit-config.yaml
# (Add configuration as you set this up)

# Install hooks
pre-commit install
```

## 🗄️ Local Database (If Needed)

### SQLite for Development
If you decide to use a local database for metadata:

```python
# Example database configuration
import sqlite3

def init_db():
    conn = sqlite3.connect('documents.db')
    conn.execute('''
        CREATE TABLE IF NOT EXISTS documents (
            id TEXT PRIMARY KEY,
            filename TEXT,
            category TEXT,
            status TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()
```

## 🔄 Hot Reload Setup

### Flask Auto-reload Configuration
```python
# In your app.py
if __name__ == '__main__':
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True,  # Enables auto-reload
        use_reloader=True
    )
```

### Frontend Auto-reload (If using modern JS)
```javascript
// If you add JavaScript build tools later
// Configure webpack-dev-server or similar
```

## 🧪 Testing in Development

### Unit Testing
```bash
# Run unit tests
pytest tests/unit/

# Run with coverage
pytest --cov=src tests/unit/

# Run specific test
pytest tests/unit/test_file_handler.py::test_validate_file
```

### Integration Testing
```bash
# Run integration tests (with LocalStack)
pytest tests/integration/

# Test specific AWS service integration
pytest tests/integration/test_s3_service.py
```

### Manual Testing Workflow
1. **Upload Test:** Try uploading different file types
2. **Virus Scan Test:** Test with EICAR test file
3. **AWS Integration:** Test with LocalStack services
4. **Error Handling:** Test invalid inputs and edge cases

## 🔍 Debugging Tools

### Flask Debug Toolbar (Optional)
```bash
pip install Flask-DebugToolbar

# Add to your app.py
from flask_debugtoolbar import DebugToolbarExtension
toolbar = DebugToolbarExtension(app)
```

### Logging Configuration
```python
# Enhanced logging for development
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/debug.log'),
        logging.StreamHandler()
    ]
)
```

### AWS Service Debugging
```python
# Enable boto3 debug logging
import boto3
boto3.set_stream_logger('boto3', logging.DEBUG)
boto3.set_stream_logger('botocore', logging.DEBUG)
```

## 📊 Development Monitoring

### Simple Performance Monitoring
```python
# Add timing decorators for development
import time
from functools import wraps

def timing_decorator(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        start = time.time()
        result = func(*args, **kwargs)
        end = time.time()
        print(f"{func.__name__} took {end - start:.2f} seconds")
        return result
    return wrapper
```

## 🔄 Development Workflow

### Daily Development Routine
1. **Start Services:**
   ```bash
   # Start LocalStack (if using)
   localstack start -d
   
   # Activate virtual environment
   source venv/bin/activate
   
   # Start Flask development server
   flask run
   ```

2. **Development Cycle:**
   - Make code changes
   - Test manually in browser
   - Run unit tests
   - Commit changes

3. **End of Day:**
   ```bash
   # Stop services
   localstack stop
   
   # Deactivate environment
   deactivate
   ```

### Branch Management
```bash
# Create feature branch
git checkout -b feature/virus-scanning

# Regular commits
git add .
git commit -m "Add virus scanning service"

# Push to remote
git push origin feature/virus-scanning
```

## 🌐 Browser Testing

### Testing Checklist
- [ ] **File Upload:** Test with different file types
- [ ] **Progress Updates:** Verify status updates work
- [ ] **Error Messages:** Test error handling
- [ ] **Responsive Design:** Test on different screen sizes

### Browser Developer Tools
- Use Network tab to monitor upload progress
- Use Console to debug JavaScript issues
- Use Application tab to check local storage (if used)

---

**📝 Development Notes:**
[Document development setup issues, solutions, and optimizations]

- [DATE] - [Development setup note]
- [DATE] - [Development setup note]