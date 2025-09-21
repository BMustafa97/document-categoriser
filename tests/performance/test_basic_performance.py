"""
Basic performance tests to ensure the application performs well.
"""
import time
import threading
from concurrent.futures import ThreadPoolExecutor
from io import BytesIO


class TestPerformance:
    """Basic performance tests."""
    
    def test_health_check_response_time(self, client):
        """Test that health check responds quickly."""
        start_time = time.time()
        
        response = client.get('/health')
        
        end_time = time.time()
        response_time = end_time - start_time
        
        assert response.status_code == 200
        assert response_time < 1.0  # Should respond in less than 1 second
    
    def test_index_page_response_time(self, client):
        """Test that index page loads quickly."""
        start_time = time.time()
        
        response = client.get('/')
        
        end_time = time.time()
        response_time = end_time - start_time
        
        assert response.status_code == 200
        assert response_time < 2.0  # Should load in less than 2 seconds
    
    def test_concurrent_health_checks(self, client):
        """Test multiple concurrent health check requests."""
        def make_request():
            response = client.get('/health')
            return response.status_code == 200
        
        # Test with 5 concurrent requests
        with ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(make_request) for _ in range(5)]
            results = [future.result() for future in futures]
        
        # All requests should succeed
        assert all(results)
    
    def test_upload_file_size_handling(self, client):
        """Test upload with different file sizes."""
        # Test small file (1KB)
        small_data = {
            'file': (BytesIO(b'x' * 1024), 'small.pdf'),
            'email': 'test@example.com'
        }
        
        response = client.post('/upload', 
                             data=small_data,
                             content_type='multipart/form-data',
                             follow_redirects=True)
        
        assert response.status_code == 200
        
        # Test medium file (100KB)
        medium_data = {
            'file': (BytesIO(b'x' * (100 * 1024)), 'medium.pdf'),
            'email': 'test@example.com'
        }
        
        response = client.post('/upload', 
                             data=medium_data,
                             content_type='multipart/form-data',
                             follow_redirects=True)
        
        assert response.status_code == 200