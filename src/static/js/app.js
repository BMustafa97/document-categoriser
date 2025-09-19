// Document Categoriser JavaScript functionality

document.addEventListener('DOMContentLoaded', function() {
    initializeFileUpload();
    initializeFormValidation();
});

// File upload functionality
function initializeFileUpload() {
    const uploadArea = document.getElementById('uploadArea');
    const fileInput = document.getElementById('file');
    const uploadForm = document.getElementById('uploadForm');
    const submitBtn = document.getElementById('submitBtn');
    
    if (!uploadArea || !fileInput) return;

    // Click to select file
    uploadArea.addEventListener('click', function(e) {
        if (e.target === fileInput) return;
        fileInput.click();
    });

    // File input change handler
    fileInput.addEventListener('change', function() {
        handleFileSelection(this.files[0]);
    });

    // Drag and drop functionality
    uploadArea.addEventListener('dragover', function(e) {
        e.preventDefault();
        uploadArea.classList.add('dragover');
    });

    uploadArea.addEventListener('dragleave', function(e) {
        e.preventDefault();
        if (!uploadArea.contains(e.relatedTarget)) {
            uploadArea.classList.remove('dragover');
        }
    });

    uploadArea.addEventListener('drop', function(e) {
        e.preventDefault();
        uploadArea.classList.remove('dragover');
        
        const files = e.dataTransfer.files;
        if (files.length > 0) {
            handleFileSelection(files[0]);
            // Manually set the file input
            const dt = new DataTransfer();
            dt.items.add(files[0]);
            fileInput.files = dt.files;
        }
    });

    // Form submission handler
    if (uploadForm) {
        uploadForm.addEventListener('submit', function(e) {
            if (submitBtn) {
                submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin me-2"></i>Uploading...';
                submitBtn.disabled = true;
            }
        });
    }
}

// Handle file selection display
function handleFileSelection(file) {
    const uploadContent = document.querySelector('.upload-content');
    const selectedFileDiv = document.querySelector('.selected-file');
    
    if (!file) {
        // No file selected, show default state
        selectedFileDiv.classList.add('d-none');
        return;
    }

    // Validate file
    const allowedTypes = ['application/pdf', 'image/png', 'image/jpeg', 'image/tiff'];
    const maxSize = 16 * 1024 * 1024; // 16MB

    if (!allowedTypes.includes(file.type)) {
        showAlert('Invalid file type. Please select a PDF, PNG, JPG, JPEG, or TIFF file.', 'danger');
        return;
    }

    if (file.size > maxSize) {
        showAlert('File too large. Maximum size is 16MB.', 'danger');
        return;
    }

    // Display selected file info
    const filename = selectedFileDiv.querySelector('.filename');
    const fileSize = selectedFileDiv.querySelector('.file-size');
    
    if (filename && fileSize) {
        filename.textContent = file.name;
        fileSize.textContent = formatFileSize(file.size);
        selectedFileDiv.classList.remove('d-none');
    }

    // Add file type icon
    const fileIcon = getFileIcon(file.type);
    filename.innerHTML = `${fileIcon} ${file.name}`;
}

// Get appropriate icon for file type
function getFileIcon(mimeType) {
    if (mimeType === 'application/pdf') {
        return '<i class="fas fa-file-pdf text-danger me-2"></i>';
    } else if (mimeType.startsWith('image/')) {
        return '<i class="fas fa-file-image text-success me-2"></i>';
    } else {
        return '<i class="fas fa-file text-primary me-2"></i>';
    }
}

// Format file size for display
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Form validation
function initializeFormValidation() {
    const form = document.getElementById('uploadForm');
    if (!form) return;

    form.addEventListener('submit', function(e) {
        const fileInput = document.getElementById('file');
        const emailInput = document.getElementById('email');
        
        let isValid = true;

        // Validate file
        if (!fileInput.files.length) {
            showAlert('Please select a file to upload.', 'danger');
            isValid = false;
        }

        // Validate email
        if (!emailInput.value.trim() || !isValidEmail(emailInput.value)) {
            showAlert('Please enter a valid email address.', 'danger');
            isValid = false;
        }

        if (!isValid) {
            e.preventDefault();
            // Reset submit button
            const submitBtn = document.getElementById('submitBtn');
            if (submitBtn) {
                submitBtn.innerHTML = '<i class="fas fa-upload me-2"></i>Upload & Process Document';
                submitBtn.disabled = false;
            }
        }
    });
}

// Email validation
function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
}

// Show alert message
function showAlert(message, type = 'info') {
    const alertContainer = document.createElement('div');
    alertContainer.className = `alert alert-${type === 'danger' ? 'danger' : 'info'} alert-dismissible fade show`;
    alertContainer.innerHTML = `
        <i class="fas fa-${type === 'danger' ? 'exclamation-triangle' : 'info-circle'} me-2"></i>
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;

    // Insert at top of main content
    const main = document.querySelector('main .container');
    if (main) {
        main.insertBefore(alertContainer, main.firstChild);
        
        // Auto-remove after 5 seconds
        setTimeout(() => {
            if (alertContainer.parentNode) {
                alertContainer.remove();
            }
        }, 5000);
    }
}

// Utility function to check processing status
async function checkProcessingStatus(jobId) {
    try {
        const response = await fetch(`/status/${jobId}`);
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error checking status:', error);
        throw error;
    }
}

// Copy text to clipboard
function copyToClipboard(text) {
    if (navigator.clipboard) {
        return navigator.clipboard.writeText(text);
    } else {
        // Fallback for older browsers
        const textArea = document.createElement('textarea');
        textArea.value = text;
        textArea.style.position = 'fixed';
        textArea.style.opacity = '0';
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
        return Promise.resolve();
    }
}

// Initialize tooltips if Bootstrap is available
if (typeof bootstrap !== 'undefined') {
    document.addEventListener('DOMContentLoaded', function() {
        const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
        tooltipTriggerList.map(function(tooltipTriggerEl) {
            return new bootstrap.Tooltip(tooltipTriggerEl);
        });
    });
}

// Progress bar animation
function animateProgressBar(element, targetValue, duration = 1000) {
    const startValue = 0;
    const startTime = Date.now();
    
    function updateProgress() {
        const elapsed = Date.now() - startTime;
        const progress = Math.min(elapsed / duration, 1);
        const currentValue = startValue + (targetValue - startValue) * progress;
        
        element.style.width = currentValue + '%';
        element.setAttribute('aria-valuenow', currentValue);
        
        if (progress < 1) {
            requestAnimationFrame(updateProgress);
        }
    }
    
    requestAnimationFrame(updateProgress);
}

// Smooth scroll to element
function scrollToElement(elementId, offset = 0) {
    const element = document.getElementById(elementId);
    if (element) {
        const elementPosition = element.getBoundingClientRect().top + window.pageYOffset;
        const offsetPosition = elementPosition - offset;
        
        window.scrollTo({
            top: offsetPosition,
            behavior: 'smooth'
        });
    }
}