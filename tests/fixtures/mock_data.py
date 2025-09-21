# Test data and mock responses for unit tests

# Mock Textract response
SAMPLE_TEXTRACT_RESPONSE = {
    "JobStatus": "SUCCEEDED",
    "DocumentMetadata": {
        "Pages": 1
    },
    "Blocks": [
        {
            "BlockType": "PAGE",
            "Geometry": {
                "BoundingBox": {
                    "Width": 1.0,
                    "Height": 1.0,
                    "Left": 0.0,
                    "Top": 0.0
                }
            },
            "Id": "page-1"
        },
        {
            "BlockType": "WORD",
            "Text": "Sample",
            "Confidence": 99.5,
            "Geometry": {
                "BoundingBox": {
                    "Width": 0.1,
                    "Height": 0.05,
                    "Left": 0.1,
                    "Top": 0.1
                }
            },
            "Id": "word-1"
        },
        {
            "BlockType": "WORD",
            "Text": "Document",
            "Confidence": 98.2,
            "Geometry": {
                "BoundingBox": {
                    "Width": 0.15,
                    "Height": 0.05,
                    "Left": 0.25,
                    "Top": 0.1
                }
            },
            "Id": "word-2"
        }
    ]
}

# Mock Comprehend response
SAMPLE_COMPREHEND_RESPONSE = {
    "Languages": [
        {
            "LanguageCode": "en",
            "Score": 0.9999
        }
    ]
}

# Mock entities response
SAMPLE_ENTITIES_RESPONSE = {
    "Entities": [
        {
            "Score": 0.8,
            "Type": "PERSON",
            "Text": "John Doe",
            "BeginOffset": 0,
            "EndOffset": 8
        },
        {
            "Score": 0.9,
            "Type": "ORGANIZATION",
            "Text": "ABC Company",
            "BeginOffset": 20,
            "EndOffset": 31
        }
    ]
}

# Mock key phrases response
SAMPLE_KEY_PHRASES_RESPONSE = {
    "KeyPhrases": [
        {
            "Score": 0.95,
            "Text": "financial report",
            "BeginOffset": 0,
            "EndOffset": 16
        },
        {
            "Score": 0.88,
            "Text": "quarterly results",
            "BeginOffset": 25,
            "EndOffset": 42
        }
    ]
}

# Mock sentiment response
SAMPLE_SENTIMENT_RESPONSE = {
    "Sentiment": "NEUTRAL",
    "SentimentScore": {
        "Positive": 0.1,
        "Negative": 0.05,
        "Neutral": 0.8,
        "Mixed": 0.05
    }
}

# Sample extracted text for testing
SAMPLE_EXTRACTED_TEXT = """
Sample Document

This is a test document containing sample text for processing.
It includes various types of information including:

- Financial data
- Contact information
- Business details
- Important dates

John Doe
ABC Company
123 Main Street
Anytown, ST 12345
Phone: (555) 123-4567
Email: john.doe@abccompany.com

Date: September 19, 2025
Subject: Quarterly Financial Report

The quarterly results show positive growth across all sectors.
Revenue increased by 15% compared to the previous quarter.
Operating expenses remained within budget constraints.

Thank you for your attention to this matter.

Sincerely,
John Doe
Financial Analyst
"""