# Smart Document Categoriser & Extractor

> **Author:** Bilal Mustafa  
> **Status:** 🚧 In Development  
> **Last Updated:** 21-09-2025
> **Live URL:** [LIVE URL](https://document-categoriser.thecoder97.com/)

## 📋 Project Overview

Build a Flask web app where users can upload documents (PDFs, images, etc.). The app scans for viruses, extracts text using **Amazon Textract**, categorises the content using **Amazon Comprehend**, and stores metadata and files in **S3**. Notifications are sent via **SES**, and the app is containerised and deployed using **ECR + ALB**.

## 🎯 Project Goals

- [ ] **Primary Goal:** Create a secure document processing pipeline
- [ ] **Secondary Goal:** Implement intelligent document categorisation
- [ ] **Secondary Goal:** Deploy scalable containerised solution on AWS

## 🏗️ Architecture Components

### Core Components Status

| Component | Status | Notes | Documentation |
|-----------|--------|-------|---------------|
| **Flask Frontend** | 🚧  Started | Simple UI for file upload and status display | [Link to docs/](#) |
| **Virus Scanning** | ⏳ Not Started | ClamAV or third-party API integration | [Link to docs/](#) |
| **File Storage (S3)** | 🚧  Started | Store clean files and metadata | [Link to docs/](#) |
| **Text Extraction (Textract)** | ⏳ Not Started | Extract text from PDFs and images | [Link to docs/](#) |
| **Content Analysis (Comprehend)** | ⏳ Not Started | Language detection, entity extraction, classification | [Link to docs/](#) |
| **Notification System (SES)** | ⏳ Not Started | Email confirmations and results | [Link to docs/](#) |
| **Containerisation & Deployment** | ✅   Not Started | Docker + ECR + Fargate + ALB | [Link to docs/](#) |

### Status Legend
- ⏳ **Not Started** - Component not yet implemented
- 🚧 **In Progress** - Currently working on this component
- ✅ **Completed** - Component fully implemented and tested
- 🔧 **Needs Review** - Implementation complete, needs testing/review
- ❌ **Blocked** - Cannot proceed due to dependencies or issues

## 🔧 AWS Services Implementation

| Service | Purpose | Implementation Status | Configuration Notes |
|---------|---------|----------------------|-------------------|
| **S3** | Store uploaded documents | ⏳ Not Started | Bucket name: `[YOUR_BUCKET_NAME]` |
| **Textract** | Extract text from documents | ⏳ Not Started | Region: `[YOUR_REGION]` |
| **Comprehend** | Categorise and analyse content | ⏳ Not Started | Custom classifiers: `[LIST_HERE]` |
| **SES** | Send email notifications | ⏳ Not Started | Verified email: `[YOUR_EMAIL]` |
| **ECR** | Store Docker images | ✅  Completed | Repository: `[YOUR_ECR_REPO]` |
| **ALB** | Route traffic to Flask app | ✅  Completed | Domain: `[YOUR_DOMAIN]` |
| **Fargate/EC2** | Host containerised app | ✅  Completed | Instance type: `[INSTANCE_TYPE]` |

## 📁 Project Structure

```
document-categoriser/
├── README.md                 # This file - project overview and progress
├── OnePageIdea.md           # Original project concept
├── docs/                    # 📚 Comprehensive documentation
│   ├── README.md           # Documentation overview
│   ├── architecture/       # System design and architecture
│   │   ├── system-design.md
│   │   ├── aws-services.md
│   │   └── diagrams/
│   ├── development/        # Development guides and setup
│   │   ├── setup.md
│   │   ├── local-dev.md
│   │   └── testing.md
│   ├── deployment/         # Deployment and infrastructure
│   │   ├── docker.md
│   │   ├── aws-deployment.md
│   │   └── ci-cd.md
│   └── api/               # API documentation
│       ├── endpoints.md
│       └── schemas.md
├── src/                    # Source code
│   ├── app.py             # Main Flask application
│   ├── config/            # Configuration files
│   ├── services/          # AWS service integrations
│   ├── utils/             # Utility functions
│   └── templates/         # HTML templates
├── tests/                 # Test files
├── requirements.txt       # Python dependencies
├── Dockerfile            # Container configuration
├── docker-compose.yml    # Local development setup
└── .env.example          # Environment variables template
```

## 🚀 Development Milestones

### Phase 1: Core Application Setup
- [ ] Set up Flask application structure
- [ ] Create basic file upload interface
- [ ] Implement local file handling
- [ ] Set up logging and error handling
- [ ] **Target Completion:** [SET_DATE]

### Phase 2: AWS Integration
- [ ] Configure AWS credentials and permissions
- [ ] Implement S3 file storage
- [ ] Integrate Amazon Textract for text extraction
- [ ] Add Amazon Comprehend for content analysis
- [ ] **Target Completion:** [SET_DATE]

### Phase 3: Security & Notifications
- [ ] Implement virus scanning (ClamAV/API)
- [ ] Set up Amazon SES for notifications
- [ ] Add input validation and sanitization
- [ ] Implement error handling and retry logic
- [ ] **Target Completion:** [SET_DATE]

### Phase 4: Containerisation & Deployment
- [ ] Create Dockerfile and docker-compose
- [ ] Set up Amazon ECR repository
- [ ] Configure Fargate deployment
- [ ] Set up Application Load Balancer
- [ ] Implement CI/CD pipeline
- [ ] **Target Completion:** [SET_DATE]

## 📚 Documentation Structure

The `docs/` folder contains comprehensive documentation organized by topic:

- **[docs/architecture/](docs/architecture/)** - System design, AWS service configurations, and architecture diagrams
- **[docs/development/](docs/development/)** - Setup guides, local development instructions, and testing procedures
- **[docs/deployment/](docs/deployment/)** - Docker configuration, AWS deployment guides, and CI/CD setup
- **[docs/api/](docs/api/)** - API endpoint documentation and data schemas

Each documentation section will be populated as you implement the corresponding components.

## 🛠️ Current Development Focus

**Currently Working On:** [UPDATE_THIS_SECTION]

**Next Up:** [UPDATE_THIS_SECTION]

**Blockers/Issues:** [UPDATE_THIS_SECTION]

## 📈 Progress Tracking

### Overall Progress: [X]% Complete

- **Phase 1 (Core App):** 0% ⏳
- **Phase 2 (AWS Integration):** 0% ⏳
- **Phase 3 (Security & Notifications):** 0% ⏳
- **Phase 4 (Deployment):** 0% ⏳

### Recent Updates
- [DATE] - Project template created
- [Add your updates here as you progress]

## 🔗 Quick Links

- [Original Idea](OnePageIdea.md) - The initial project concept
- [Architecture Documentation](docs/architecture/) - Detailed system design
- [Setup Guide](docs/development/setup.md) - Get started with development
- [Deployment Guide](docs/deployment/) - Deploy to AWS

## 📞 Notes & Decisions

Use this space to document important decisions, lessons learned, and notes as you build:

- Project Start Date - 19/09/2025

---