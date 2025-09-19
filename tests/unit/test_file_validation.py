import pytest
import sys
import os

# Add src to path so we can import our app functions
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'src'))

from app import allowed_file


class TestFileValidation:
    """Test file validation functions."""

    def test_allowed_file_valid_extensions(self):
        """Test that allowed file extensions return True."""
        valid_files = [
            'document.pdf',
            'image.png',
            'photo.jpg',
            'picture.jpeg',
            'scan.tiff',
            'DOCUMENT.PDF',  # Test case insensitive
            'IMAGE.PNG',
            'PHOTO.JPG'
        ]
        
        for filename in valid_files:
            assert allowed_file(filename) == True, f"Expected {filename} to be allowed"

    def test_allowed_file_invalid_extensions(self):
        """Test that disallowed file extensions return False."""
        invalid_files = [
            'document.txt',
            'script.py',
            'data.csv',
            'archive.zip',
            'executable.exe',
            'document.doc',
            'document.docx',
            'presentation.ppt',
            'spreadsheet.xls'
        ]
        
        for filename in invalid_files:
            assert allowed_file(filename) == False, f"Expected {filename} to be disallowed"

    def test_allowed_file_no_extension(self):
        """Test files without extensions."""
        no_extension_files = [
            'filename',
            'document',
            'image',
            'file_without_extension'
        ]
        
        for filename in no_extension_files:
            assert allowed_file(filename) == False, f"Expected {filename} to be disallowed"

    def test_allowed_file_multiple_dots(self):
        """Test files with multiple dots in filename."""
        multi_dot_files = [
            'my.document.pdf',
            'backup.v1.2.png',
            'file.name.with.dots.jpg',
            'archive.tar.gz',  # Should be False (gz extension)
            'config.json.backup'  # Should be False (backup extension)
        ]
        
        expected_results = [True, True, True, False, False]
        
        for filename, expected in zip(multi_dot_files, expected_results):
            result = allowed_file(filename)
            assert result == expected, f"Expected {filename} to return {expected}, got {result}"

    def test_allowed_file_edge_cases(self):
        """Test edge cases for file validation."""
        edge_cases = [
            '.pdf',          # Filename starting with dot
            'pdf',           # Extension without dot
            '.hidden.pdf',   # Hidden file with valid extension
            'file.',         # File ending with dot
            '',              # Empty filename
            '.',             # Single dot
            '..',            # Double dot
        ]
        
        expected_results = [True, False, True, False, False, False, False]
        
        for filename, expected in zip(edge_cases, expected_results):
            result = allowed_file(filename)
            assert result == expected, f"Expected {filename} to return {expected}, got {result}"

    def test_allowed_file_case_sensitivity(self):
        """Test that file extension checking is case insensitive."""
        case_variations = [
            ('document.PDF', True),
            ('image.Png', True),
            ('photo.JPG', True),
            ('scan.JPEG', True),
            ('file.TiFf', True),
            ('document.TXT', False),
            ('script.PY', False)
        ]
        
        for filename, expected in case_variations:
            result = allowed_file(filename)
            assert result == expected, f"Expected {filename} to return {expected}, got {result}"

    def test_allowed_file_unicode_filename(self):
        """Test files with unicode characters in filename."""
        unicode_files = [
            'документ.pdf',      # Cyrillic
            'fichier.png',       # French
            'archivo.jpg',       # Spanish
            'ファイル.jpeg',      # Japanese
            '文档.tiff',         # Chinese
            'tést_filé.pdf',     # Accented characters
            'üñíçödé.png'        # Various accents
        ]
        
        for filename in unicode_files:
            assert allowed_file(filename) == True, f"Expected {filename} to be allowed"

    def test_allowed_extensions_constant(self):
        """Test that the ALLOWED_EXTENSIONS set contains expected values."""
        # Import the constant to test it directly
        from app import ALLOWED_EXTENSIONS
        
        expected_extensions = {'pdf', 'png', 'jpg', 'jpeg', 'tiff'}
        assert ALLOWED_EXTENSIONS == expected_extensions
        
        # Ensure all extensions are lowercase
        for ext in ALLOWED_EXTENSIONS:
            assert ext.islower(), f"Extension {ext} should be lowercase"

    def test_security_file_traversal_protection(self):
        """Test protection against file traversal attacks."""
        malicious_files = [
            '../../../etc/passwd.pdf',
            '..\\..\\windows\\system32\\config.png',
            '/etc/shadow.jpg',
            'C:\\Windows\\System32\\config.jpeg',
            '../../secret.tiff'
        ]
        
        # These should still be considered valid files by allowed_file function
        # (The actual security protection is handled by secure_filename in Flask)
        for filename in malicious_files:
            # The function only checks extensions, not path traversal
            assert allowed_file(filename) == True, f"allowed_file should only check extension for {filename}"

    def test_long_filename_handling(self):
        """Test handling of very long filenames."""
        # Create a very long filename
        long_name = 'a' * 200 + '.pdf'
        assert allowed_file(long_name) == True
        
        # Long filename with invalid extension
        long_name_invalid = 'a' * 200 + '.txt'
        assert allowed_file(long_name_invalid) == False