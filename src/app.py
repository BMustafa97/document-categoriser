from flask import Flask, render_template, request, flash, redirect, url_for, jsonify
import os
from werkzeug.utils import secure_filename
import uuid
from datetime import datetime

# Create Flask app
app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size

# Configuration
app.config['UPLOAD_FOLDER'] = 'uploads'
ALLOWED_EXTENSIONS = {'pdf', 'png', 'jpg', 'jpeg', 'tiff'}

# Ensure upload directory exists
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

def allowed_file(filename):
    """Check if file extension is allowed."""
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    """Main page with upload form."""
    return render_template('index.html')

@app.route('/upload', methods=['POST'])
def upload_file():
    """Handle file upload."""
    try:
        # Check if file was uploaded
        if 'file' not in request.files:
            flash('No file selected', 'error')
            return redirect(url_for('index'))
        
        file = request.files['file']
        email = request.form.get('email', '').strip()
        
        # Validate inputs
        if file.filename == '':
            flash('No file selected', 'error')
            return redirect(url_for('index'))
        
        if not email:
            flash('Email address is required', 'error')
            return redirect(url_for('index'))
        
        if not allowed_file(file.filename):
            flash(f'File type not supported. Allowed types: {", ".join(ALLOWED_EXTENSIONS)}', 'error')
            return redirect(url_for('index'))
        
        # Generate unique job ID and secure filename
        job_id = str(uuid.uuid4())
        filename = secure_filename(file.filename)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        unique_filename = f"{timestamp}_{job_id[:8]}_{filename}"
        
        # Save file temporarily
        file_path = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        file.save(file_path)
        
        # Get file info
        file_size = os.path.getsize(file_path)
        
        flash(f'File "{filename}" uploaded successfully! Processing will begin shortly.', 'success')
        
        # For now, return success page with job details
        # In future, this will trigger the processing pipeline
        return render_template('upload_success.html', 
                             job_id=job_id,
                             filename=filename,
                             file_size=file_size,
                             email=email)
    
    except Exception as e:
        app.logger.error(f"Upload error: {str(e)}")
        flash('An error occurred during upload. Please try again.', 'error')
        return redirect(url_for('index'))

@app.route('/status/<job_id>')
def check_status(job_id):
    """Check processing status (placeholder)."""
    # This is a placeholder - in future this will check actual processing status
    return jsonify({
        'job_id': job_id,
        'status': 'uploaded',
        'message': 'File uploaded successfully. Processing will be implemented next.'
    })

@app.route('/health')
def health_check():
    """Health check endpoint for load balancers."""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '0.1.0'
    })

@app.errorhandler(413)
def too_large(e):
    """Handle file too large error."""
    flash('File too large. Maximum size is 16MB.', 'error')
    return redirect(url_for('index'))

@app.errorhandler(404)
def not_found(e):
    """Handle 404 errors."""
    return render_template('404.html'), 404

@app.errorhandler(500)
def server_error(e):
    """Handle 500 errors."""
    app.logger.error(f"Server error: {str(e)}")
    return render_template('500.html'), 500

if __name__ == '__main__':
    # Create upload directory if it doesn't exist
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    
    app.run(debug=True, host='0.0.0.0', port=5001)
