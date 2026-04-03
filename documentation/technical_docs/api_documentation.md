---
title: "API Documentation"
output: html_document
---

# Mental Health Risk Prediction API Documentation

## Overview

The Mental Health Risk Prediction API provides RESTful endpoints for predicting student mental health risk levels based on academic performance, behavioral data, and mental health survey responses. The API is built using Plumber and follows REST principles with comprehensive error handling and security features.

## Base URL

```
http://localhost:8000
```

## Authentication

All API endpoints require authentication using Bearer token authentication. Include your API key in the Authorization header:

```
Authorization: Bearer your_api_key_here
```

### API Key Configuration

API keys can be configured through:
1. Environment variable: `API_KEY`
2. Configuration file: `config/config.yaml`

## Endpoints

### 1. Health Check

#### GET /health

Returns the health status of the API and system components.

**Request:**
```bash
curl -X GET "http://localhost:8000/health"
```

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0",
  "model_available": true,
  "data_available": true
}
```

**Response (503 Service Unavailable):**
```json
{
  "status": "unhealthy",
  "error": "Model file not found",
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Status Codes:**
- `200 OK`: System is healthy
- `503 Service Unavailable`: System is unhealthy or degraded

### 2. Mental Health Risk Prediction

#### POST /predict

Predicts mental health risk level based on student data.

**Request Headers:**
```
Content-Type: application/json
Authorization: Bearer your_api_key_here
```

**Request Body:**
```json
{
  "semester": 3,
  "gpa": 7.5,
  "attendance_rate": 90,
  "course_failures": 0,
  "academic_probation": "No",
  "phq_total": 10,
  "gad_total": 8,
  "self_harm_thoughts": "No"
}
```

**Response (200 OK):**
```json
{
  "prediction": "Medium",
  "probabilities": {
    "High": 0.15,
    "Low": 0.25,
    "Medium": 0.60
  },
  "confidence": 0.60,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

**Response (400 Bad Request):**
```json
{
  "error": "400 - Input validation errors: GPA must be between 0.0 and 10.0",
  "status": 400
}
```

**Response (401 Unauthorized):**
```json
{
  "error": "401 - Unauthorized: Invalid API key",
  "status": 401
}
```

**Response (500 Internal Server Error):**
```json
{
  "error": "500 - Internal server error: Model loading failed",
  "status": 500
}
```

**Status Codes:**
- `200 OK`: Prediction successful
- `400 Bad Request`: Invalid input parameters
- `401 Unauthorized`: Invalid or missing API key
- `500 Internal Server Error`: Server error

### 3. API Information

#### GET /info

Returns API information and documentation.

**Request:**
```bash
curl -X GET "http://localhost:8000/info"
```

**Response (200 OK):**
```json
{
  "name": "Mental Health Risk Prediction API",
  "version": "1.0.0",
  "description": "API for predicting student mental health risk levels",
  "endpoints": {
    "health": "/health",
    "predict": "/predict",
    "info": "/info"
  },
  "input_schema": {
    "required_fields": [
      "semester",
      "gpa",
      "attendance_rate",
      "course_failures",
      "academic_probation",
      "phq_total",
      "gad_total",
      "self_harm_thoughts"
    ],
    "field_types": {
      "semester": "integer",
      "gpa": "numeric",
      "attendance_rate": "numeric",
      "course_failures": "integer",
      "academic_probation": "character",
      "phq_total": "integer",
      "gad_total": "integer",
      "self_harm_thoughts": "character"
    },
    "validation_rules": {
      "semester": {
        "min": 1,
        "max": 12
      },
      "gpa": {
        "min": 0.0,
        "max": 10.0
      },
      "attendance_rate": {
        "min": 0,
        "max": 100
      },
      "course_failures": {
        "min": 0,
        "max": 5
      },
      "academic_probation": {
        "values": ["Yes", "No"]
      },
      "phq_total": {
        "min": 0,
        "max": 27
      },
      "gad_total": {
        "min": 0,
        "max": 21
      },
      "self_harm_thoughts": {
        "values": ["Yes", "No"]
      }
    }
  },
  "timestamp": "2024-01-15T10:30:00Z"
}
```

## Input Parameters

### Required Fields

| Field | Type | Description | Validation |
|-------|------|-------------|------------|
| `semester` | integer | Current semester (1-12) | 1 ≤ semester ≤ 12 |
| `gpa` | numeric | Grade Point Average | 0.0 ≤ gpa ≤ 10.0 |
| `attendance_rate` | numeric | Attendance percentage | 0 ≤ attendance_rate ≤ 100 |
| `course_failures` | integer | Number of failed courses | 0 ≤ course_failures ≤ 5 |
| `academic_probation` | string | Academic probation status | "Yes" or "No" |
| `phq_total` | integer | PHQ-9 depression score | 0 ≤ phq_total ≤ 27 |
| `gad_total` | integer | GAD-7 anxiety score | 0 ≤ gad_total ≤ 21 |
| `self_harm_thoughts` | string | Self-harm thoughts | "Yes" or "No" |

### Field Descriptions

#### Academic Fields

- **semester**: The current academic semester (1-12, where 1-8 typically represent undergraduate years)
- **gpa**: Grade Point Average on a 0.0 to 10.0 scale
- **attendance_rate**: Percentage of classes attended (0-100%)
- **course_failures**: Number of courses failed in the current academic period
- **academic_probation**: Whether the student is currently on academic probation

#### Mental Health Fields

- **phq_total**: Total score from the Patient Health Questionnaire-9 (PHQ-9)
  - 0-4: Minimal depression
  - 5-9: Mild depression
  - 10-14: Moderate depression
  - 15-19: Moderately severe depression
  - 20-27: Severe depression

- **gad_total**: Total score from the Generalized Anxiety Disorder-7 (GAD-7)
  - 0-4: Minimal anxiety
  - 5-9: Mild anxiety
  - 10-14: Moderate anxiety
  - 15-21: Severe anxiety

- **self_harm_thoughts**: Whether the student has reported thoughts of self-harm

## Response Format

### Prediction Response

The prediction endpoint returns:

- **prediction**: The predicted risk level ("Low", "Medium", or "High")
- **probabilities**: Probability scores for each risk level
- **confidence**: Confidence score for the prediction (0.0-1.0)
- **timestamp**: ISO 8601 timestamp of the prediction

### Risk Levels

- **Low**: Minimal risk of mental health issues
- **Medium**: Moderate risk requiring monitoring
- **High**: High risk requiring immediate intervention

## Error Handling

### Error Response Format

All error responses follow this format:

```json
{
  "error": "Error description",
  "status": 400,
  "timestamp": "2024-01-15T10:30:00Z"
}
```

### Common Error Codes

| Status Code | Description | Common Causes |
|-------------|-------------|---------------|
| 400 | Bad Request | Invalid input parameters, validation errors |
| 401 | Unauthorized | Missing or invalid API key |
| 500 | Internal Server Error | Server errors, model loading failures |

### Validation Errors

The API performs comprehensive validation on all input parameters:

1. **Type Validation**: Ensures parameters are of the correct data type
2. **Range Validation**: Validates parameter values are within acceptable ranges
3. **Value Validation**: Ensures categorical variables have valid values
4. **Required Field Validation**: Ensures all required fields are provided

## Rate Limiting

The API implements rate limiting to prevent abuse:

- **Default Limit**: 100 requests per minute per API key
- **Headers**: Rate limit information is included in response headers
- **Exceeded Limit**: Returns 429 Too Many Requests status code

## Logging and Monitoring

### Request Logging

All API requests are logged with:
- Timestamp
- IP address
- Request method and endpoint
- Response status code
- Processing time
- Error details (if applicable)

### Log Files

- **Access Logs**: `api/logs/api_access.log`
- **Error Logs**: `api/logs/api_error.log`

## Security Features

### Input Sanitization

All input parameters are sanitized to prevent:
- SQL injection
- XSS attacks
- Command injection
- Path traversal attacks

### Authentication

- Bearer token authentication
- API key validation
- Secure token storage

### Data Protection

- No sensitive data in error messages
- Secure logging practices
- Data anonymization

## Usage Examples

### Python Example

```python
import requests
import json

# API configuration
api_url = "http://localhost:8000"
api_key = "your_api_key_here"

# Request headers
headers = {
    "Content-Type": "application/json",
    "Authorization": f"Bearer {api_key}"
}

# Request data
data = {
    "semester": 3,
    "gpa": 7.5,
    "attendance_rate": 90,
    "course_failures": 0,
    "academic_probation": "No",
    "phq_total": 10,
    "gad_total": 8,
    "self_harm_thoughts": "No"
}

# Make prediction request
response = requests.post(
    f"{api_url}/predict",
    headers=headers,
    json=data
)

if response.status_code == 200:
    result = response.json()
    print(f"Prediction: {result['prediction']}")
    print(f"Confidence: {result['confidence']}")
else:
    print(f"Error: {response.json()['error']}")
```

### R Example

```r
library(httr)
library(jsonlite)

# API configuration
api_url <- "http://localhost:8000"
api_key <- "your_api_key_here"

# Request data
data <- list(
  semester = 3,
  gpa = 7.5,
  attendance_rate = 90,
  course_failures = 0,
  academic_probation = "No",
  phq_total = 10,
  gad_total = 8,
  self_harm_thoughts = "No"
)

# Make prediction request
response <- POST(
  paste0(api_url, "/predict"),
  add_headers(
    "Content-Type" = "application/json",
    "Authorization" = paste("Bearer", api_key)
  ),
  body = toJSON(data, auto_unbox = TRUE)
)

if (status_code(response) == 200) {
  result <- content(response)
  cat("Prediction:", result$prediction, "\n")
  cat("Confidence:", result$confidence, "\n")
} else {
  cat("Error:", content(response)$error, "\n")
}
```

### JavaScript Example

```javascript
// API configuration
const apiUrl = 'http://localhost:8000';
const apiKey = 'your_api_key_here';

// Request data
const data = {
  semester: 3,
  gpa: 7.5,
  attendance_rate: 90,
  course_failures: 0,
  academic_probation: "No",
  phq_total: 10,
  gad_total: 8,
  self_harm_thoughts: "No"
};

// Make prediction request
fetch(`${apiUrl}/predict`, {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${apiKey}`
  },
  body: JSON.stringify(data)
})
.then(response => response.json())
.then(result => {
  if (result.error) {
    console.error('Error:', result.error);
  } else {
    console.log('Prediction:', result.prediction);
    console.log('Confidence:', result.confidence);
  }
})
.catch(error => {
  console.error('Request failed:', error);
});
```

## Testing

### Health Check Test

```bash
curl -X GET "http://localhost:8000/health"
```

### Prediction Test

```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_api_key_here" \
  -d '{
    "semester": 3,
    "gpa": 7.5,
    "attendance_rate": 90,
    "course_failures": 0,
    "academic_probation": "No",
    "phq_total": 10,
    "gad_total": 8,
    "self_harm_thoughts": "No"
  }'
```

## Support

For API support and questions:
- Check the health endpoint for system status
- Review error messages for troubleshooting
- Contact the development team for assistance
- Check the system logs for detailed error information

## Version History

- **v1.0.0**: Initial API release with core prediction functionality
- **v1.1.0**: Added comprehensive input validation and error handling
- **v1.2.0**: Enhanced security features and logging