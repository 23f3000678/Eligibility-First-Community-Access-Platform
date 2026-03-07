# 🚀 AWS Deployment Guide - DataShade AI Eligibility Platform

This guide will help you deploy the DataShade platform to AWS, making it accessible to everyone via a public URL.

## 📋 Overview

We'll deploy:
- **Frontend** → AWS S3 + CloudFront (Static Website Hosting)
- **Backend** → AWS Lambda + API Gateway (Already deployed)
- **Database** → DynamoDB (Already configured)
- **Authentication** → AWS Cognito (Already configured)

**Estimated Time:** 30-45 minutes  
**Cost:** ~$1-5/month (mostly free tier eligible)

---

## 🎯 Prerequisites

Before starting, ensure you have:
- ✅ AWS Account with billing enabled
- ✅ AWS CLI installed and configured
- ✅ Backend already deployed to Lambda (from README.md)
- ✅ Frontend working locally

---

## 📦 Part 1: Build Frontend for Production

### Step 1: Update Frontend Environment for Production

Edit `packages/frontend/.env`:

```env
# Production API URL (your actual API Gateway URL)
VITE_API_BASE_URL=https://your-api-id.execute-api.ap-south-1.amazonaws.com/v1

# AWS Cognito Configuration
VITE_AWS_REGION=ap-south-1
VITE_USER_POOL_ID=ap-south-1_XXXXXXXXX
VITE_USER_POOL_CLIENT_ID=your-client-id-here
```

### Step 2: Build Frontend

```bash
cd packages/frontend
npm run build
```

This creates a `dist/` folder with optimized production files.

**Verify build:**
- Check `packages/frontend/dist/` folder exists
- Should contain `index.html`, `assets/`, etc.

---

## 🌐 Part 2: Deploy Frontend to AWS S3

### Step 1: Create S3 Bucket

```bash
# Replace 'datashade-eligibility-platform' with your unique bucket name
aws s3 mb s3://datashade-eligibility-platform --region ap-south-1
```

**Note:** S3 bucket names must be globally unique. If the name is taken, try:
- `datashade-eligibility-yourname`
- `eligibility-platform-yourcompany`

### Step 2: Enable Static Website Hosting

```bash
aws s3 website s3://datashade-eligibility-platform \
  --index-document index.html \
  --error-document index.html
```

### Step 3: Configure Bucket Policy for Public Access

Create a file `bucket-policy.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::datashade-eligibility-platform/*"
    }
  ]
}
```

**Replace** `datashade-eligibility-platform` with your bucket name.

Apply the policy:

```bash
aws s3api put-bucket-policy \
  --bucket datashade-eligibility-platform \
  --policy file://bucket-policy.json
```

### Step 4: Disable Block Public Access

```bash
aws s3api put-public-access-block \
  --bucket datashade-eligibility-platform \
  --public-access-block-configuration \
    "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
```

### Step 5: Upload Frontend Files

```bash
cd packages/frontend
aws s3 sync dist/ s3://datashade-eligibility-platform/ --delete
```

**Flags explained:**
- `sync` - Uploads only changed files
- `--delete` - Removes old files from S3

### Step 6: Get Website URL

Your website is now live at:

```
http://datashade-eligibility-platform.s3-website.ap-south-1.amazonaws.com
```

**Test it:** Open the URL in your browser!

---

## ⚡ Part 3: Add CloudFront CDN (Optional but Recommended)

CloudFront provides:
- ✅ HTTPS support
- ✅ Faster global access
- ✅ Custom domain support
- ✅ Better security

### Step 1: Create CloudFront Distribution

```bash
aws cloudfront create-distribution \
  --origin-domain-name datashade-eligibility-platform.s3-website.ap-south-1.amazonaws.com \
  --default-root-object index.html
```

**This takes 15-20 minutes to deploy.**

### Step 2: Get CloudFront URL

```bash
aws cloudfront list-distributions \
  --query "DistributionList.Items[0].DomainName" \
  --output text
```

You'll get a URL like: `d1234abcd5678.cloudfront.net`

### Step 3: Configure CloudFront for SPA

CloudFront needs to handle React Router properly.

**Via AWS Console:**
1. Go to CloudFront → Your Distribution
2. Click "Error Pages" tab
3. Click "Create Custom Error Response"
4. Configure:
   - HTTP Error Code: `403`
   - Customize Error Response: `Yes`
   - Response Page Path: `/index.html`
   - HTTP Response Code: `200`
5. Repeat for error code `404`

### Step 4: Update Cognito Callback URLs

Since you now have a CloudFront URL, update Cognito:

1. Go to AWS Console → Cognito → User Pools
2. Select your user pool
3. Go to "App Integration" → "App clients"
4. Click your app client
5. Edit "Hosted UI settings"
6. Add Callback URLs:
   ```
   https://d1234abcd5678.cloudfront.net
   http://localhost:5173
   ```
7. Add Sign-out URLs:
   ```
   https://d1234abcd5678.cloudfront.net
   http://localhost:5173
   ```
8. Save changes

---

## 🔒 Part 4: Enable HTTPS with Custom Domain (Optional)

### Prerequisites:
- Own a domain name (e.g., from GoDaddy, Namecheap, Route53)

### Step 1: Request SSL Certificate

```bash
aws acm request-certificate \
  --domain-name datashade.yourdomain.com \
  --validation-method DNS \
  --region us-east-1
```

**Important:** ACM certificates for CloudFront MUST be in `us-east-1` region!

### Step 2: Validate Certificate

1. Go to AWS Console → Certificate Manager (us-east-1 region)
2. Click your certificate
3. Click "Create records in Route 53" (if using Route53)
4. Or manually add CNAME records to your DNS provider

**Wait for validation** (5-30 minutes)

### Step 3: Add Custom Domain to CloudFront

1. Go to CloudFront → Your Distribution → Edit
2. Add "Alternate Domain Names (CNAMEs)":
   ```
   datashade.yourdomain.com
   ```
3. Select your SSL certificate
4. Save changes

### Step 4: Update DNS

Add a CNAME record in your DNS:
```
Type: CNAME
Name: datashade
Value: d1234abcd5678.cloudfront.net
```

**Wait for DNS propagation** (5-60 minutes)

Your site will be available at: `https://datashade.yourdomain.com`

---

## 🔄 Part 5: Continuous Deployment Setup

### Option 1: Manual Deployment Script

Create `deploy-frontend.sh` (or `.bat` for Windows):

```bash
#!/bin/bash
echo "Building frontend..."
cd packages/frontend
npm run build

echo "Uploading to S3..."
aws s3 sync dist/ s3://datashade-eligibility-platform/ --delete

echo "Invalidating CloudFront cache..."
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"

echo "✅ Deployment complete!"
```

**Windows version** (`deploy-frontend.bat`):

```bat
@echo off
echo Building frontend...
cd packages\frontend
call npm run build

echo Uploading to S3...
aws s3 sync dist/ s3://datashade-eligibility-platform/ --delete

echo Invalidating CloudFront cache...
aws cloudfront create-invalidation --distribution-id YOUR_DISTRIBUTION_ID --paths "/*"

echo Deployment complete!
pause
```

Make it executable:
```bash
chmod +x deploy-frontend.sh
```

### Option 2: GitHub Actions (Automated)

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Node.js
      uses: actions/setup-node@v2
      with:
        node-version: '18'
    
    - name: Install dependencies
      run: |
        cd packages/frontend
        npm install
    
    - name: Build
      run: |
        cd packages/frontend
        npm run build
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ap-south-1
    
    - name: Deploy to S3
      run: |
        aws s3 sync packages/frontend/dist/ s3://datashade-eligibility-platform/ --delete
    
    - name: Invalidate CloudFront
      run: |
        aws cloudfront create-invalidation --distribution-id ${{ secrets.CLOUDFRONT_DISTRIBUTION_ID }} --paths "/*"
```

**Setup GitHub Secrets:**
1. Go to GitHub → Your Repo → Settings → Secrets
2. Add:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `CLOUDFRONT_DISTRIBUTION_ID`

---

## 🧪 Part 6: Testing Deployment

### Test Checklist:

1. **Frontend Access**
   - [ ] Can access the website via S3 URL
   - [ ] Can access via CloudFront URL (if configured)
   - [ ] HTTPS works (if custom domain configured)

2. **Authentication**
   - [ ] Can sign up with email
   - [ ] Receive verification email
   - [ ] Can verify account
   - [ ] Can login
   - [ ] Can logout

3. **Profile Management**
   - [ ] Can create profile
   - [ ] Can edit profile
   - [ ] Profile data persists

4. **Eligibility Check**
   - [ ] Can search schemes
   - [ ] Can select scheme
   - [ ] Can check eligibility
   - [ ] AI reasoning displays correctly

5. **Scheme Discovery**
   - [ ] Can search for new schemes
   - [ ] AI discovers schemes
   - [ ] Can add schemes to database

---

## 💰 Cost Estimation

### Monthly Costs (Approximate):

| Service | Free Tier | After Free Tier |
|---------|-----------|-----------------|
| **S3 Storage** | 5 GB free | $0.023/GB |
| **S3 Requests** | 20,000 GET free | $0.0004/1000 requests |
| **CloudFront** | 1 TB transfer free | $0.085/GB |
| **Lambda** | 1M requests free | $0.20/1M requests |
| **DynamoDB** | 25 GB free | $0.25/GB |
| **API Gateway** | 1M requests free | $3.50/1M requests |
| **Cognito** | 50,000 MAU free | $0.0055/MAU |

**Estimated Total:** $1-5/month for small-scale usage (mostly free tier)

---

## 🔧 Troubleshooting

### Issue: "Access Denied" on S3 URL

**Solution:**
- Check bucket policy is applied
- Verify public access is not blocked
- Ensure bucket name in policy matches actual bucket

### Issue: CloudFront shows old content

**Solution:**
```bash
# Invalidate CloudFront cache
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### Issue: "Failed to fetch" API errors

**Solution:**
- Verify API Gateway URL in frontend `.env`
- Check CORS is enabled on API Gateway
- Ensure Lambda functions are deployed

### Issue: Cognito redirect errors

**Solution:**
- Add CloudFront URL to Cognito callback URLs
- Check Cognito app client configuration
- Verify redirect URIs match exactly (including https://)

### Issue: React Router 404 errors

**Solution:**
- Configure CloudFront error pages (see Part 3, Step 3)
- Ensure error responses redirect to `/index.html`

---

## 🔄 Updating Your Deployment

### Update Frontend:

```bash
# 1. Make changes to code
# 2. Build
cd packages/frontend
npm run build

# 3. Deploy
aws s3 sync dist/ s3://datashade-eligibility-platform/ --delete

# 4. Invalidate cache (if using CloudFront)
aws cloudfront create-invalidation \
  --distribution-id YOUR_DISTRIBUTION_ID \
  --paths "/*"
```

### Update Backend:

```bash
cd packages/backend

# 1. Make changes to code
# 2. Build
npm run build

# 3. Prepare and bundle
node prepare-lambda.js
node bundle-lambda.js

# 4. Deploy specific function
aws lambda update-function-code \
  --function-name eligibility-mvp-profile \
  --zip-file fileb://lambda-dist/profile-handler.zip \
  --region ap-south-1
```

---

## 📊 Monitoring Your Deployment

### CloudWatch Logs

**View Lambda logs:**
```bash
aws logs tail /aws/lambda/eligibility-mvp-profile --follow --region ap-south-1
```

**View API Gateway logs:**
1. Go to API Gateway → Your API → Stages
2. Enable CloudWatch Logs
3. View in CloudWatch console

### CloudFront Metrics

1. Go to CloudFront → Your Distribution
2. Click "Monitoring" tab
3. View requests, data transfer, error rates

### Cost Monitoring

1. Go to AWS Console → Billing Dashboard
2. Enable "Cost Explorer"
3. Set up billing alerts

---

## 🎉 Success!

Your DataShade AI Eligibility Platform is now live and accessible to everyone!

**Your URLs:**
- S3 Website: `http://your-bucket.s3-website.ap-south-1.amazonaws.com`
- CloudFront: `https://d1234abcd5678.cloudfront.net`
- Custom Domain: `https://datashade.yourdomain.com` (if configured)

**Share your platform and help people discover their eligibility for government schemes! 🚀**

---

## 📚 Additional Resources

- [AWS S3 Static Website Hosting](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [CloudFront Documentation](https://docs.aws.amazon.com/cloudfront/)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [Cognito Documentation](https://docs.aws.amazon.com/cognito/)

---

**Need Help?** Check CloudWatch logs for errors or review the troubleshooting section above.
