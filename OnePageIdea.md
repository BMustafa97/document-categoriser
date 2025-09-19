## **Smart Document Categoriser & Extractor**

### 🎯 Goal:

Build a Flask web app where users can upload documents (PDFs, images, etc.). The app scans for viruses, extracts text using **Amazon Textract**, categorises the content using **Amazon Comprehend**, and stores metadata and files in **S3**. Notifications are sent via **SES**, and the app is containerised and deployed using **ECR + ALB**.

## 🏗️ High-Level Architecture:

1. **Frontend (Flask App)**:
    - Simple UI for file upload.
    - Status updates and results display.
2. **Virus Scanning**:
    - Use **ClamAV** or integrate with a third-party API.
    - Reject infected files.
3. **File Storage**:
    - Upload clean files to **Amazon S3**.
    - Store metadata (filename, category, extracted text) in **DynamoDB** or a local DB.
4. **Text Extraction**:
    - Use **Amazon Textract** to extract text from documents.
    - Handle PDFs, scanned images, etc.
5. **Content Categorisation**:
    - Use **Amazon Comprehend** to:
        - Detect dominant language.
        - Extract entities.
        - Classify document type (e.g., invoice, resume, report).
6. **Notification System**:
    - Send email confirmation/results to user via **Amazon SES**.
7. **Containerisation & Deployment**:
    - Dockerise the Flask app.
    - Push to **Amazon ECR**.
    - Deploy using **Fargate** behind an **Application Load Balancer (ALB)**.

## 🔧 AWS Services Used:

| Service | Purpose |
| --- | --- |
| **S3** | Store uploaded documents |
| **Textract** | Extract text from documents |
| **Comprehend** | Categorise and analyse document content |
| **SES** | Send email notifications |
| **ECR** | Store Docker images |
| **ALB** | Route traffic to Flask app |
| **Fargate/EC2** | Host the containerised app |

Author Bilal Mustafa