# DataShade - AI Eligibility Check Platform

An AI-powered platform to help users determine their eligibility for government schemes and community programs in India.

## 🚀 Features

- **User Profile Management** - Create and manage user profiles with demographic information
- **AI-Powered Eligibility Check** - Evaluate eligibility for government schemes using Amazon Nova AI
- **Scheme Discovery** - Discover new schemes using natural language queries
- **Document Upload** - Upload and manage required documents
- **Multi-language Support** - Support for English, Hindi, and Tamil
- **Secure Authentication** - AWS Cognito-based email authentication

## 📋 Prerequisites

Before setting up the project, ensure you have:

- **Node.js** (v18 or higher) - [Download](https://nodejs.org/)
- **npm** (comes with Node.js)
- **Git** - [Download](https://git-scm.com/)
- **AWS Account** - [Sign up](https://aws.amazon.com/)
- **AWS CLI** - [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

## 🛠️ Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd Eligibility-First-Community-Access-Platform
```

### 2. Install Dependencies

```bash
# Install root dependencies
npm install

# Install frontend dependencies
cd packages/frontend
npm install
cd ../..

# Install backend dependencies
cd packages/backend
npm install
cd ../..
```

## ⚙️ Configuration

### Backend Configuration

#### Step 1: Configure AWS CLI

```bash
aws configure
```

Enter your AWS credentials:
- **AWS Access Key ID**: Your AWS access key
- **AWS Secret Access Key**: Your AWS secret key
- **Default region name**: `ap-south-1` (Mumbai)
- **Default output format**: `json`

#### Step 2: Create Backend Environment File

Create `packages/backend/.env`:

```env
# AWS Configuration
AWS_REGION=ap-south-1
DYNAMODB_TABLE_NAME=eligibility-mvp-table

# Bedrock Configuration (Amazon Nova AI)
BEDROCK_MODEL_ID=apac.amazon.nova-lite-v1:0
```

#### Step 3: Deploy Backend to AWS Lambda

The backend is already deployed to AWS Lambda. If you need to redeploy:

```bash
cd packages/backend

# Build TypeScript
npm run build

# Prepare Lambda package
node prepare-lambda.js

# Bundle Lambda functions
node bundle-lambda.js

# Deploy to AWS (replace function names with your actual Lambda function names)
aws lambda update-function-code --function-name eligibility-mvp-profile --zip-file fileb://lambda-dist/profile-handler.zip --region ap-south-1
aws lambda update-function-code --function-name eligibility-mvp-eligibility --zip-file fileb://lambda-dist/eligibility-handler.zip --region ap-south-1
aws lambda update-function-code --function-name eligibility-mvp-document --zip-file fileb://lambda-dist/document-handler.zip --region ap-south-1
aws lambda update-function-code --function-name eligibility-mvp-scheme --zip-file fileb://lambda-dist/scheme-handler.zip --region ap-south-1
```

### Frontend Configuration

#### Step 1: Get AWS Resources Information

You need the following from your AWS account:

1. **API Gateway URL**: Go to AWS Console → API Gateway → Your API → Stages → Copy "Invoke URL"
2. **Cognito User Pool ID**: Go to AWS Console → Cognito → User Pools → Copy "User pool ID"
3. **Cognito App Client ID**: Go to AWS Console → Cognito → User Pools → App Integration → Copy "Client ID"

#### Step 2: Create Frontend Environment File

Create `packages/frontend/.env`:

```env
# API Configuration
VITE_API_BASE_URL=https://your-api-id.execute-api.ap-south-1.amazonaws.com/v1

# AWS Cognito Configuration
VITE_AWS_REGION=ap-south-1
VITE_USER_POOL_ID=ap-south-1_XXXXXXXXX
VITE_USER_POOL_CLIENT_ID=your-client-id-here
```

**Replace the placeholders:**
- `your-api-id` → Your actual API Gateway ID
- `ap-south-1_XXXXXXXXX` → Your actual Cognito User Pool ID
- `your-client-id-here` → Your actual Cognito App Client ID

## 🚀 Running the Application

### Start Frontend Development Server

**Option 1: Using the batch file (Windows)**
```bash
START_FRONTEND.bat
```

**Option 2: Manual start**
```bash
cd packages/frontend
npm run dev
```

The frontend will be available at: **http://localhost:5173**

### Backend

The backend is already running on AWS Lambda. No local backend server needed!

## 📱 Using the Application

### 1. Sign Up

1. Go to http://localhost:5173
2. Click "Sign up"
3. Enter your email and password
4. Check your email for verification code
5. Enter the 6-digit code to verify your account

### 2. Create Profile

1. After login, fill in your profile information:
   - Name (optional)
   - Age range
   - Location (state, district, rural/urban)
   - Education level
   - Employment status
   - Other demographic information

2. Provide consent for data processing
3. Click "Save Profile"

### 3. Check Eligibility

1. Go to "Check Eligibility" tab
2. Search for a scheme using the search box
3. Select a scheme from the dropdown
4. Click "Check Eligibility"
5. View your eligibility results with AI-powered reasoning

### 4. Discover New Schemes

1. Go to "🤖 Discover Schemes" tab
2. Enter a natural language query (e.g., "education schemes for students in Karnataka")
3. Click "Search"
4. Review AI-discovered schemes
5. Click "Add to Database" to save schemes for future use

## 🔧 AWS Resources Setup

If you're setting up from scratch, you need to create these AWS resources:

### 1. DynamoDB Table

```bash
aws dynamodb create-table \
  --table-name eligibility-mvp-table \
  --attribute-definitions \
    AttributeName=PK,AttributeType=S \
    AttributeName=SK,AttributeType=S \
    AttributeName=GSI1PK,AttributeType=S \
    AttributeName=GSI1SK,AttributeType=S \
  --key-schema \
    AttributeName=PK,KeyType=HASH \
    AttributeName=SK,KeyType=RANGE \
  --global-secondary-indexes \
    "[{\"IndexName\":\"GSI1\",\"KeySchema\":[{\"AttributeName\":\"GSI1PK\",\"KeyType\":\"HASH\"},{\"AttributeName\":\"GSI1SK\",\"KeyType\":\"RANGE\"}],\"Projection\":{\"ProjectionType\":\"ALL\"},\"ProvisionedThroughput\":{\"ReadCapacityUnits\":5,\"WriteCapacityUnits\":5}}]" \
  --provisioned-throughput \
    ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region ap-south-1
```

### 2. Cognito User Pool

1. Go to AWS Console → Cognito → Create User Pool
2. Configure sign-in options:
   - Sign-in with email
   - Enable email verification
3. Configure password policy (minimum 8 characters)
4. Enable MFA (optional)
5. Create app client (no client secret)
6. Note down User Pool ID and App Client ID

### 3. Lambda Functions

Create 4 Lambda functions:
- `eligibility-mvp-profile` - User profile management
- `eligibility-mvp-eligibility` - Eligibility evaluation
- `eligibility-mvp-document` - Document management
- `eligibility-mvp-scheme` - Scheme discovery and management

**Configuration for each:**
- Runtime: Node.js 20.x
- Handler: `<handler-name>.handler`
- Timeout: 30-90 seconds
- Memory: 512-1024 MB
- Environment variables:
  - `TABLE_NAME=eligibility-mvp-table`
  - `DYNAMODB_TABLE_NAME=eligibility-mvp-table`

### 4. API Gateway

1. Create REST API
2. Create resources and methods for each Lambda function
3. Enable CORS
4. Deploy to stage (e.g., "v1")
5. Note down the Invoke URL

### 5. IAM Permissions

Ensure Lambda execution role has permissions for:
- DynamoDB (read/write)
- Bedrock (invoke model)
- CloudWatch Logs (write logs)

## 📚 Project Structure

```
Eligibility-First-Community-Access-Platform/
├── packages/
│   ├── frontend/              # React + TypeScript frontend
│   │   ├── src/
│   │   │   ├── components/    # React components
│   │   │   ├── contexts/      # React contexts (Auth)
│   │   │   ├── pages/         # Page components
│   │   │   ├── services/      # API services
│   │   │   └── App.tsx        # Main app component
│   │   ├── .env               # Frontend environment variables
│   │   └── package.json
│   │
│   └── backend/               # Node.js + TypeScript backend
│       ├── src/
│       │   ├── handlers/      # Lambda handlers
│       │   ├── repositories/  # Data access layer
│       │   ├── services/      # Business logic
│       │   ├── types/         # TypeScript types
│       │   └── utils/         # Utility functions
│       ├── .env               # Backend environment variables
│       └── package.json
│
├── docs/                      # Documentation
├── START_FRONTEND.bat         # Quick start script (Windows)
├── README.md                  # This file
└── package.json               # Root package.json
```

## 🐛 Troubleshooting

### Frontend Issues

**Issue: "Failed to fetch" or CORS errors**
- Check if API Gateway URL is correct in `.env`
- Ensure CORS is enabled on API Gateway
- Verify you're logged in (check browser console)

**Issue: "User pool does not exist"**
- Verify Cognito User Pool ID in `.env`
- Check AWS region is correct (`ap-south-1`)

### Backend Issues

**Issue: Lambda function not found**
- Verify Lambda function names match your AWS setup
- Check AWS region is `ap-south-1`

**Issue: DynamoDB access denied**
- Ensure Lambda execution role has DynamoDB permissions
- Verify table name is `eligibility-mvp-table`

**Issue: Bedrock access denied**
- Ensure Lambda execution role has Bedrock permissions
- Verify model ID is `apac.amazon.nova-lite-v1:0`
- Check if Bedrock is available in `ap-south-1` region

### Authentication Issues

**Issue: Not receiving verification email**
- Check spam folder
- Verify email in Cognito console
- Check Cognito email configuration

**Issue: "User already exists" error**
- User might be unconfirmed - check Cognito console
- Delete user from Cognito and try again

## 🔐 Security Notes

- Never commit `.env` files to Git (already in `.gitignore`)
- Keep AWS credentials secure
- Use IAM roles with least privilege
- Enable MFA on AWS account
- Regularly rotate AWS access keys

## 📄 License

This project is for educational and demonstration purposes.

## 👥 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review AWS CloudWatch logs for Lambda functions
3. Check browser console for frontend errors

## 🎯 Next Steps

After setup:
1. Test user signup and login
2. Create a test profile
3. Try checking eligibility for sample schemes
4. Discover new schemes using AI
5. Customize the platform for your needs

---

**Happy Coding! 🚀**
