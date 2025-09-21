import pytest
import json
import os
from io import BytesIO


class TestFlaskRoutes:
    """Test Flask application routes."""

    def test_index_route(self, client):
        """Test the main index page loads correctly."""
        response = client.get('/')
        assert response.status_code == 200
        # Check that the upload form is present
        assert b'file' in response.data
        assert b'email' in response.data

    def test_health_check(self, client):
        """Test the health check endpoint."""
        response = client.get('/health')
        assert response.status_code == 200
        
        data = json.loads(response.data)
        assert data['status'] == 'healthy'
        assert 'timestamp' in data
        assert 'version' in data

    def test_upload_no_file(self, client):
        """Test upload without selecting a file."""
        response = client.post('/upload', data={
            'email': 'test@example.com'
        }, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'No file selected' in response.data

    def test_upload_empty_filename(self, client):
        """Test upload with empty filename."""
        data = {
            'file': (BytesIO(b''), ''),
            'email': 'test@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'No file selected' in response.data

    def test_upload_no_email(self, client, sample_pdf):
        """Test upload without email address."""
        data = {
            'file': (sample_pdf, 'test.pdf'),
            'email': ''
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'Email address is required' in response.data

    def test_upload_invalid_file_type(self, client):
        """Test upload with invalid file type."""
        data = {
            'file': (BytesIO(b'invalid content'), 'test.txt'),
            'email': 'test@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'File type not supported' in response.data

    def test_upload_valid_pdf(self, client, sample_pdf):
        """Test successful PDF upload."""
        data = {
            'file': (sample_pdf, 'test.pdf'),
            'email': 'test@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'uploaded successfully' in response.data
        assert b'test@example.com' in response.data

    def test_upload_valid_png(self, client, sample_image):
        """Test successful PNG upload."""
        data = {
            'file': (sample_image, 'test.png'),
            'email': 'user@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'uploaded successfully' in response.data

    def test_upload_valid_jpg(self, client):
        """Test successful JPG upload."""
        jpg_content = BytesIO(b'\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01')
        data = {
            'file': (jpg_content, 'test.jpg'),
            'email': 'user@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'uploaded successfully' in response.data

    def test_status_endpoint(self, client):
        """Test the status checking endpoint."""
        job_id = 'test-job-123'
        response = client.get(f'/status/{job_id}')
        
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data['job_id'] == job_id
        assert 'status' in data
        assert 'message' in data

    def test_404_error_handler(self, client):
        """Test 404 error handling."""
        response = client.get('/nonexistent-page')
        assert response.status_code == 404

    def test_file_too_large_error(self, client):
        """Test file size limit error handling."""
        # Create a large file (mock data)
        large_content = BytesIO(b'x' * (17 * 1024 * 1024))  # 17MB
        data = {
            'file': (large_content, 'large.pdf'),
            'email': 'test@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        # Should trigger the file too large error
        assert response.status_code in [200, 413]  # 413 or redirected with flash message

    def test_upload_with_special_characters_in_filename(self, client, sample_pdf):
        """Test upload with special characters in filename."""
        data = {
            'file': (sample_pdf, 'test file with spaces & symbols!.pdf'),
            'email': 'test@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'uploaded successfully' in response.data

    def test_upload_with_unicode_filename(self, client, sample_pdf):
        """Test upload with unicode characters in filename."""
        data = {
            'file': (sample_pdf, 'tést_filé_ñame.pdf'),
            'email': 'test@example.com'
        }
        response = client.post('/upload', data=data, follow_redirects=True)
        
        assert response.status_code == 200
        assert b'uploaded successfully' in response.data