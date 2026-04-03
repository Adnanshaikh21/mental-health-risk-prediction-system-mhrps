# Mental Health Risk Prediction System

A comprehensive machine learning system for predicting student mental health risk levels based on academic performance, behavioral data, and mental health survey responses.

## 🎯 Project Overview

This system provides:
- **Data Pipeline**: Automated data generation, preprocessing, and feature engineering
- **ML Model**: Random Forest classifier with SMOTE for balanced predictions
- **REST API**: Plumber-based API for real-time predictions
- **Role-based Dashboards**: Separate interfaces for Educators, Counselors, and Administrators
- **Security**: Authorization, audit logging, and data anonymization
- **Automation**: Scheduled tasks for data ingestion and model retraining

## 🏗️ Architecture

```
├── data/                 # Data processing pipeline
├── model/               # ML model training and evaluation
├── api/                 # REST API endpoints
├── dashboards/          # Role-based web interfaces
├── security/            # Authentication and audit logging
├── automation/          # Scheduled tasks and monitoring
├── deployment/          # Docker and cloud configurations
├── tests/              # Comprehensive test suite
└── config/             # Configuration files
```

## 🚀 Quick Start

### Prerequisites

- R (version 4.0 or higher)
- RStudio (recommended)
- Docker (for containerized deployment)
- PostgreSQL (optional, for database storage)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Second
   ```

2. **Install R dependencies**
   ```r
   source("packages.R")
   ```

3. **Generate sample data**
   ```r
   source("data/generate_dummy_data.R")
   source("data/integrate_data.R")
   source("data/preprocess_data.R")
   source("data/feature_engineering.R")
   ```

4. **Train the model**
   ```r
   source("model/train_model.R")
   ```

5. **Start the API**
   ```r
   source("api/run_api.R")
   ```

6. **Launch dashboards**
   ```r
   source("dashboards/dashboards.R")
   ```

## 📋 Detailed Setup Instructions

### 1. Environment Setup

#### Windows
```powershell
# Install R from https://cran.r-project.org/
# Install RStudio from https://posit.co/download/rstudio-desktop/
# Install Docker Desktop from https://www.docker.com/products/docker-desktop/
```

#### macOS
```bash
# Install R
brew install r

# Install RStudio
brew install --cask rstudio

# Install Docker
brew install --cask docker
```

#### Linux (Ubuntu/Debian)
```bash
# Install R
sudo apt update
sudo apt install r-base r-base-dev

# Install RStudio
wget https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2022.02.1-461-amd64.deb
sudo dpkg -i rstudio-2022.02.1-461-amd64.deb

# Install Docker
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker
```

### 2. Package Installation

The system automatically installs all required packages. Key packages include:

**Core ML & Data Processing:**
- `caret`, `randomForest`, `smotefamily` - Machine learning
- `dplyr`, `tidyr`, `tidyverse` - Data manipulation
- `ggplot2`, `corrplot` - Visualization

**Web & API:**
- `plumber` - REST API
- `shiny`, `shinydashboard` - Web dashboards
- `DT` - Interactive tables

**Database & Security:**
- `RPostgres`, `DBI` - Database connectivity
- `digest` - Data anonymization
- `config` - Configuration management

**Utilities:**
- `jsonlite` - JSON handling
- `lubridate` - Date/time processing
- `taskscheduleR` - Task scheduling

### 3. Configuration

#### Environment Variables
Create a `.env` file in the project root:
```bash
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mdb
DB_USER=your_username
DB_PASSWORD=your_password

# API Configuration
API_KEY=your_secure_api_key
API_HOST=127.0.0.1
API_PORT=8000

# Dashboard Ports
EDUCATOR_PORT=3838
COUNSELOR_PORT=3839
ADMIN_PORT=3840

# Security
ENCRYPTION_KEY=your_encryption_key
```

#### Configuration Files
- `config/config.yaml` - Main configuration
- `config/database_config.yaml` - Database settings
- `config/privacy_settings.yaml` - Privacy and compliance settings

### 4. Data Pipeline

The data pipeline consists of several stages:

1. **Data Generation** (`data/generate_dummy_data.R`)
   - Creates synthetic student data
   - Includes academic, behavioral, and mental health metrics

2. **Data Integration** (`data/integrate_data.R`)
   - Combines multiple data sources
   - Applies data anonymization
   - Assigns mental health risk levels

3. **Data Preprocessing** (`data/preprocess_data.R`)
   - Handles missing values
   - Applies feature scaling
   - Converts data types

4. **Feature Engineering** (`data/feature_engineering.R`)
   - Creates derived features
   - Removes highly correlated features
   - Selects optimal feature set

### 5. Model Training

The ML pipeline includes:

1. **Data Preparation**
   - Train/test split (70/30)
   - SMOTE for class balance
   - Feature selection

2. **Model Training**
   - Random Forest with hyperparameter tuning
   - Cross-validation
   - Performance evaluation

3. **Model Evaluation**
   - Confusion matrix
   - ROC curves
   - Feature importance analysis

### 6. API Setup

The REST API provides:

- **Health Check**: `/health`
- **Prediction**: `/predict` (POST)
- **Authentication**: Bearer token
- **Input Validation**: Comprehensive parameter checking
- **Error Handling**: Structured error responses

#### API Usage Example
```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Authorization: Bearer your_api_key" \
  -H "Content-Type: application/json" \
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

### 7. Dashboard Access

Three role-based dashboards are available:

- **Educator Dashboard**: Port 3838
  - Academic performance metrics
  - Risk level overview
  - Student search functionality

- **Counselor Dashboard**: Port 3839
  - High-risk student alerts
  - Detailed student profiles
  - Intervention tracking

- **Admin Dashboard**: Port 3840
  - System overview
  - Model performance metrics
  - User management

## 🔧 Troubleshooting

### Common Issues

1. **Package Installation Failures**
   ```r
   # Clear package cache
   remove.packages(c("package_name"))
   install.packages("package_name", dependencies = TRUE)
   ```

2. **Port Conflicts**
   ```r
   # Check port availability
   netstat -an | grep :8000
   # Change ports in config/config.yaml
   ```

3. **Database Connection Issues**
   ```r
   # Test database connection
   source("data/database_connect.R")
   con <- connect_db()
   dbDisconnect(con)
   ```

4. **Model Training Failures**
   ```r
   # Check data availability
   file.exists("data/output/features_data.rds")
   # Regenerate data if needed
   source("data/generate_dummy_data.R")
   ```

### Log Files

- API logs: `api/logs/`
- Data processing logs: `data/logs/`
- Security logs: `security/output/`

## 🧪 Testing

Run the comprehensive test suite:

```r
# Unit tests
source("tests/unit_tests/test_api.R")
source("tests/unit_tests/test_model.R")
source("tests/unit_tests/test_data_processing.R")

# Integration tests
source("tests/integration_tests/test_pipeline.R")
source("tests/integration_tests/test_dashboard.R")

# User acceptance tests
source("tests/user_acceptance_tests/test_admin_dashboard.R")
source("tests/user_acceptance_tests/test_counselor_dashboard.R")
source("tests/user_acceptance_tests/test_educator_dashboard.R")
```

## 🚀 Deployment

### Docker Deployment

```bash
# Build and run with Docker Compose
cd deployment/docker
docker-compose up --build
```

### Manual Deployment

1. **Production Environment**
   ```bash
   # Set production environment variables
   export R_ENV=production
   export API_KEY=production_api_key
   
   # Start services
   Rscript api/run_api.R &
   Rscript dashboards/dashboards.R &
   ```

2. **Monitoring**
   ```r
   # Start monitoring services
   source("automation/monitoring/system_health_monitor.R")
   source("automation/monitoring/performance_monitoring.R")
   ```

## 🔒 Security

### Data Protection
- Student IDs are anonymized using SHA-256 hashing
- All sensitive data is encrypted at rest
- GDPR and FERPA compliance features

### Access Control
- Role-based authorization
- API key authentication
- Audit logging for all actions

### Best Practices
- Regular security updates
- Input validation and sanitization
- Secure credential management

## 📊 Performance

### System Requirements
- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Storage**: 10GB available space

### Optimization
- Model caching for faster predictions
- Database indexing for queries
- Load balancing for high traffic

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the troubleshooting section

## 🔄 Version History

- **v1.0.0**: Initial release with core functionality
- **v1.1.0**: Added comprehensive testing and documentation
- **v1.2.0**: Enhanced security and error handling

---

**Note**: This system is designed for educational institutions and should be used in compliance with local privacy and data protection regulations.
