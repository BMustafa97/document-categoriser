import pytest
import os
import sys
import tempfile
from io import BytesIO

# Add src to path so we can import our app
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))

from app import app as flask_app


@pytest.fixture
def app():
    """Create and configure a new app instance for each test."""
    # Create a temporary file to serve as the database
    db_fd, flask_app.config['DATABASE'] = tempfile.mkstemp()
    flask_app.config['TESTING'] = True
    flask_app.config['WTF_CSRF_ENABLED'] = False
    flask_app.config['UPLOAD_FOLDER'] = tempfile.mkdtemp()
    
    with flask_app.app_context():
        yield flask_app
    
    os.close(db_fd)
    os.unlink(flask_app.config['DATABASE'])


@pytest.fixture
def client(app):
    """A test client for the app."""
    return app.test_client()


@pytest.fixture
def runner(app):
    """A test runner for the app's Click commands."""
    return app.test_cli_runner()


@pytest.fixture
def sample_pdf():
    """Create a mock PDF file for testing."""
    # Create a minimal PDF-like content for testing
    pdf_content = b"%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n>>\nendobj\nxref\n0 4\n0000000000 65535 f \n0000000015 00000 n \n0000000074 00000 n \n0000000120 00000 n \ntrailer\n<<\n/Size 4\n/Root 1 0 R\n>>\nstartxref\n178\n%%EOF"
    return BytesIO(pdf_content)


@pytest.fixture
def sample_image():
    """Create a mock image file for testing."""
    # Create a minimal PNG-like content for testing
    png_content = b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x00\x01\x00\x18\xdd\x8d\xb4\x00\x00\x00\x00IEND\xaeB`\x82'
    return BytesIO(png_content)


@pytest.fixture
def invalid_file():
    """Create an invalid file type for testing."""
    return BytesIO(b'This is not a valid file type')


@pytest.fixture
def sample_files():
    """Dictionary of sample files for testing."""
    return {
        'valid_pdf': (BytesIO(b"%PDF-1.4\nSample PDF content"), 'test.pdf'),
        'valid_png': (BytesIO(b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR'), 'test.png'),
        'valid_jpg': (BytesIO(b'\xff\xd8\xff\xe0\x00\x10JFIF'), 'test.jpg'),
        'invalid_txt': (BytesIO(b'Plain text content'), 'test.txt'),
        'no_extension': (BytesIO(b'Some content'), 'testfile'),
        'empty_file': (BytesIO(b''), 'empty.pdf')
    }