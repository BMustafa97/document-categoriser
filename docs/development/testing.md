# Testing Strategy & Procedures

> **Status:** ⏳ Template Ready - Update as you implement testing

## 🧪 Testing Overview

### Testing Pyramid
- **Unit Tests** (70%) - Fast, isolated component tests
- **Integration Tests** (20%) - AWS service and component integration
- **End-to-End Tests** (10%) - Full workflow testing

### Testing Goals
- [ ] **Code Coverage:** Target 80%+ coverage
- [ ] **AWS Integration:** Test all AWS service interactions
- [ ] **Error Handling:** Test failure scenarios and edge cases
- [ ] **Performance:** Validate processing time expectations
- [ ] **Security:** Test file validation and virus scanning

## 🏗️ Test Structure

### Directory Organization
```
tests/
├── __init__.py
├── conftest.py              # Shared test configuration
├── unit/                    # Unit tests
│   ├── __init__.py
│   ├── test_file_handler.py
│   ├── test_validators.py
│   ├── services/
│   │   ├── test_s3_service.py
│   │   ├── test_textract_service.py
│   │   ├── test_comprehend_service.py
│   │   └── test_ses_service.py
├── integration/             # Integration tests
│   ├── __init__.py
│   ├── test_aws_services.py
│   ├── test_upload_flow.py
│   └── test_processing_pipeline.py
├── e2e/                     # End-to-end tests
│   ├── __init__.py
│   └── test_complete_workflow.py
├── fixtures/                # Test data
│   ├── sample.pdf
│   ├── sample.png
│   ├── eicar.txt           # Virus test file
│   └── invalid_file.xyz
└── mocks/                   # Mock responses
    ├── textract_responses.py
    ├── comprehend_responses.py
    └── ses_responses.py
```

## 🔬 Unit Testing

### Test Configuration (conftest.py)
```python
import pytest
import os
import sys
from unittest.mock import MagicMock

# Add src to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

@pytest.fixture
def client():
    """Flask test client fixture."""
    from app import create_app
    app = create_app({'TESTING': True})
    with app.test_client() as client:
        with app.app_context():
            yield client

@pytest.fixture
def mock_s3():
    """Mock S3 service."""
    return MagicMock()

@pytest.fixture
def mock_textract():
    """Mock Textract service."""
    return MagicMock()

@pytest.fixture
def sample_pdf():
    """Sample PDF file for testing."""
    return os.path.join(os.path.dirname(__file__), 'fixtures', 'sample.pdf')
```

### Example Unit Tests

#### File Handler Tests
```python
# tests/unit/test_file_handler.py
import pytest
from src.utils.file_handler import FileHandler, ValidationError

class TestFileHandler:
    def test_validate_file_valid_pdf(self, sample_pdf):
        """Test validation of valid PDF file."""
        handler = FileHandler()
        result = handler.validate_file(sample_pdf)
        assert result.is_valid == True
        assert result.file_type == 'pdf'
    
    def test_validate_file_invalid_extension(self):
        """Test validation rejects invalid file extensions."""
        handler = FileHandler()
        with pytest.raises(ValidationError):
            handler.validate_file('test.xyz')
    
    def test_file_size_validation(self):
        """Test file size limits."""
        # Add test implementation
        pass
    
    def test_mime_type_validation(self):
        """Test MIME type validation."""
        # Add test implementation
        pass
```

#### Service Tests
```python
# tests/unit/services/test_s3_service.py
import pytest
from unittest.mock import patch, MagicMock
from src.services.s3_service import S3Service

class TestS3Service:
    @patch('boto3.client')
    def test_upload_file_success(self, mock_boto_client):
        """Test successful file upload to S3."""
        mock_s3_client = MagicMock()
        mock_boto_client.return_value = mock_s3_client
        
        service = S3Service()
        result = service.upload_file('test.pdf', 'bucket', 'key')
        
        assert result.success == True
        mock_s3_client.upload_file.assert_called_once()
    
    def test_upload_file_failure(self, mock_s3):
        """Test S3 upload failure handling."""
        # Add test implementation
        pass
```

## 🔗 Integration Testing

### AWS Service Integration
```python
# tests/integration/test_aws_services.py
import pytest
import boto3
from moto import mock_s3, mock_textract, mock_comprehend

@mock_s3
@mock_textract
@mock_comprehend
class TestAWSIntegration:
    def setup_method(self):
        """Setup AWS mocks for each test."""
        # Create mock S3 bucket
        self.s3_client = boto3.client('s3', region_name='us-east-1')
        self.s3_client.create_bucket(Bucket='test-bucket')
    
    def test_s3_textract_integration(self):
        """Test S3 to Textract integration."""
        # Upload file to S3
        # Trigger Textract processing
        # Verify results
        pass
    
    def test_textract_comprehend_integration(self):
        """Test Textract to Comprehend pipeline."""
        # Mock Textract response
        # Pass to Comprehend
        # Verify analysis results
        pass
```

### Upload Flow Integration
```python
# tests/integration/test_upload_flow.py
class TestUploadFlow:
    def test_complete_upload_process(self, client):
        """Test complete file upload and processing flow."""
        with open('tests/fixtures/sample.pdf', 'rb') as f:
            response = client.post('/upload', 
                data={'file': f, 'email': 'test@example.com'})
        
        assert response.status_code == 200
        data = response.get_json()
        assert 'job_id' in data
    
    def test_virus_scan_integration(self):
        """Test virus scanning in upload flow."""
        # Add test implementation
        pass
```

## 🎭 End-to-End Testing

### Complete Workflow Tests
```python
# tests/e2e/test_complete_workflow.py
import pytest
import time

class TestCompleteWorkflow:
    def test_pdf_processing_workflow(self, client):
        """Test complete PDF processing from upload to notification."""
        # 1. Upload file
        # 2. Check processing status
        # 3. Wait for completion
        # 4. Verify results
        # 5. Check notification sent
        pass
    
    def test_error_handling_workflow(self):
        """Test error handling in complete workflow."""
        pass
```

## 🦠 Security Testing

### Virus Scanning Tests
```python
# tests/unit/test_virus_scanner.py
class TestVirusScanner:
    def test_clean_file_scan(self):
        """Test scanning of clean file."""
        # Add test implementation
        pass
    
    def test_eicar_detection(self):
        """Test EICAR test virus detection."""
        # Use EICAR test string
        eicar = "X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"
        # Test virus detection
        pass
```

### Input Validation Tests
```python
# tests/unit/test_validators.py
class TestInputValidators:
    def test_email_validation(self):
        """Test email format validation."""
        pass
    
    def test_file_type_validation(self):
        """Test file type validation."""
        pass
    
    def test_sql_injection_prevention(self):
        """Test SQL injection prevention (if using database)."""
        pass
```

## 🏃‍♂️ Performance Testing

### Load Testing
```python
# tests/performance/test_load.py
import pytest
import concurrent.futures
import time

class TestPerformance:
    def test_concurrent_uploads(self):
        """Test handling multiple concurrent uploads."""
        # Simulate multiple users uploading simultaneously
        pass
    
    def test_large_file_processing(self):
        """Test processing time for large files."""
        pass
    
    def test_aws_service_timeouts(self):
        """Test timeout handling for AWS services."""
        pass
```

## 📊 Test Data Management

### Test Fixtures
```python
# tests/fixtures/test_data.py
SAMPLE_TEXTRACT_RESPONSE = {
    "JobStatus": "SUCCEEDED",
    "Blocks": [
        {
            "BlockType": "PAGE",
            "Confidence": 99.9,
            "Text": "Sample document text"
        }
    ]
}

SAMPLE_COMPREHEND_RESPONSE = {
    "Languages": [
        {"LanguageCode": "en", "Score": 0.99}
    ]
}
```

### Mock Data Generation
```python
# tests/mocks/data_generator.py
def generate_mock_document():
    """Generate mock document for testing."""
    return {
        "document_id": "test-123",
        "filename": "test.pdf",
        "status": "uploaded"
    }
```

## ⚡ Test Execution

### Running Tests
```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=src --cov-report=html

# Run specific test categories
pytest tests/unit/
pytest tests/integration/
pytest tests/e2e/

# Run with markers
pytest -m "not slow"  # Skip slow tests
pytest -m "aws"       # Run only AWS tests

# Parallel execution
pytest -n auto        # Requires pytest-xdist
```

### Test Markers
```python
# In pytest.ini or pyproject.toml
[tool.pytest.ini_options]
markers = [
    "slow: marks tests as slow",
    "aws: marks tests that require AWS services", 
    "integration: marks integration tests",
    "unit: marks unit tests"
]
```

### Continuous Integration
```yaml
# .github/workflows/test.yml (example)
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: 3.9
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        pip install pytest pytest-cov
    - name: Run tests
      run: pytest --cov=src --cov-report=xml
    - name: Upload coverage
      uses: codecov/codecov-action@v1
```

## 📋 Testing Checklists

### Pre-Commit Testing
- [ ] Run unit tests locally
- [ ] Check code coverage
- [ ] Run linting (flake8, black)
- [ ] Test critical paths manually

### Pre-Deployment Testing
- [ ] Full test suite passes
- [ ] Integration tests with real AWS services
- [ ] Load testing completed
- [ ] Security tests passed
- [ ] End-to-end workflow verified

### Testing Best Practices
- [ ] **Arrange-Act-Assert** pattern in tests
- [ ] **Descriptive test names** that explain what's being tested
- [ ] **Independent tests** that don't rely on each other
- [ ] **Mock external dependencies** in unit tests
- [ ] **Test edge cases** and error conditions
- [ ] **Keep tests fast** and focused

---

**📝 Testing Notes:**
[Document testing decisions, challenges, and improvements]

- [DATE] - [Testing decision or improvement]
- [DATE] - [Testing decision or improvement]