"""
Integration tests for the Flask application.
These tests the complete upload workflow.
"""
import pytest
import os
import tempfile
from io import BytesIO


class TestUploadIntegration:
    """Test the complete upload workflow."""
    
    def test_upload_workflow_success(self, client):
        """Test successful file upload workflow."""
        # Create a temporary file for testing
        data = {
            'file': (BytesIO(b'fake pdf content'), 'test.pdf'),
            'email': 'test@example.com'
        }
        
        response = client.post('/upload', 
                             data=data,
                             content_type='multipart/form-data',
                             follow_redirects=True)
        
        assert response.status_code == 200
        assert b'uploaded successfully' in response.data.lower()
    
    def test_upload_workflow_no_file(self, client):
        """Test upload with no file."""
        data = {
            'email': 'test@example.com'
        }
        
        response = client.post('/upload', 
                             data=data,
                             follow_redirects=True)
        
        assert response.status_code == 200
        assert b'no file selected' in response.data.lower()
    
    def test_upload_workflow_invalid_file_type(self, client):
        """Test upload with invalid file type."""
        data = {
            'file': (BytesIO(b'fake content'), 'test.txt'),
            'email': 'test@example.com'
        }
        
        response = client.post('/upload', 
                             data=data,
                             follow_redirects=True)
        
        assert response.status_code == 200
        assert b'file type not supported' in response.data.lower()
    
    def test_upload_workflow_no_email(self, client):
        """Test upload without email."""
        data = {
            'file': (BytesIO(b'fake pdf content'), 'test.pdf')
        }
        
        response = client.post('/upload', 
                             data=data,
                             follow_redirects=True)
        
        assert response.status_code == 200
        assert b'email address is required' in response.data.lower()
    
    def test_upload_creates_file(self, client, app):
        """Test that upload actually creates a file."""
        data = {
            'file': (BytesIO(b'fake pdf content'), 'integration_test.pdf'),
            'email': 'test@example.com'
        }
        
        # Count files before upload
        upload_dir = app.config['UPLOAD_FOLDER']
        files_before = len([f for f in os.listdir(upload_dir) if f.endswith('.pdf')])
        
        response = client.post('/upload', 
                             data=data,
                             content_type='multipart/form-data',
                             follow_redirects=True)
        
        # Check that a new file was created
        files_after = len([f for f in os.listdir(upload_dir) if f.endswith('.pdf')])
        assert files_after > files_before
        assert response.status_code == 200


class TestApplicationFlow:
    """Test the complete application flow."""
    
    def test_full_user_journey(self, client):
        """Test a complete user journey from index to upload success."""
        # Step 1: Visit the home page
        response = client.get('/')
        assert response.status_code == 200
        assert b'upload' in response.data.lower()
        
        # Step 2: Upload a file
        data = {
            'file': (BytesIO(b'fake pdf content'), 'journey_test.pdf'),
            'email': 'journey@example.com'
        }
        
        response = client.post('/upload', 
                             data=data,
                             content_type='multipart/form-data',
                             follow_redirects=True)
        
        assert response.status_code == 200
        assert b'uploaded successfully' in response.data.lower()
        
        # Step 3: Check health endpoint
        response = client.get('/health')
        assert response.status_code == 200
        
        json_data = response.get_json()
        assert json_data['status'] == 'healthy'
        assert 'timestamp' in json_data
        assert 'version' in json_data