# 🛑 AWS Resource Teardown Guide - Stop Charges

This guide will help you safely disable your DataShade platform and delete all AWS resources to avoid any charges.

---

## ⚠️ Important Notes Before You Start

- **Backup your data**: Once deleted, DynamoDB data cannot be recovered
- **Save your code**: Make sure your code is pushed to GitHub
- **Order matters**: Follow the steps in sequence to avoid dependency issues
- **Verification**: Check AWS Console after each step to confirm deletion

---

## 📋 Quick Teardown Checklist

Use this checklist to track your progress:

- [ ] Step 1: Disable CloudFront Distribution
- [ ] Step 2: Delete S3 Bucket Contents
- [ ] Step 3: Delete S3 Bucket
- [ ] Step 4: Delete Lambda Functions
- [ ] Step 5: Delete API Gateway
- [ ] Step 6: Delete DynamoDB Table
- [ ] Step 7: Delete Cognito User Pool
- [ ] Step 8: Verify All Resources Deleted
- [ ] Step 9: Check Billing Dashboard

---

## 🔧 Step-by-Step Teardown Process

### Step 1: Disable CloudFront Distribution

CloudFront must be disabled before it can be deleted.

**1.1 Disable the distribution:**
```bash
aws cloudfront get-distribution-config --id E3VARXR2SXA3P7 > cloudfront-current-config.json
```

**1.2 Edit the config to disable it:**

Open `cloudfront-current-config.json` and change `"Enabled": true` to `"Enabled": false`

**1.3 Get the ETag:**
```bash
aws cloudfront get-distribution --id E3VARXR2SXA3P7 --query "ETag" --output text
```

**1.4 Update the distribution (replace YOUR_ETAG with the value from above):**
```bash
aws cloudfront update-distribution --id E3VARXR2SXA3P7 --if-match YOUR_ETAG --distribution-config file://cloudfront-current-config.json
```

**1.5 Wait for deployment (takes 15-20 minutes):**
```bash
aws cloudfront get-distribution --id E3VARXR2SXA3P7 --query "Distribution.Status"
```

Wait until status shows "Deployed" (not "InProgress")

**1.6 Delete the distribution:**

Get the new ETag:
```bash
aws cloudfront get-distribution --id E3VARXR2SXA3P7 --query "ETag" --output text
```

Delete (replace YOUR_NEW_ETAG):
```bash
aws cloudfront delete-distribution --id E3VARXR2SXA3P7 --if-match YOUR_NEW_ETAG
```

**Cost Impact**: ✅ Stops CloudFront charges immediately

---

### Step 2: Delete S3 Bucket Contents

S3 buckets must be empty before deletion.

**2.1 List all objects (verify what will be deleted):**
```bash
aws s3 ls s3://datashade-eligibility-platform/ --recursive
```

**2.2 Delete all objects:**
```bash
aws s3 rm s3://datashade-eligibility-platform/ --recursive
```

**2.3 Verify bucket is empty:**
```bash
aws s3 ls s3://datashade-eligibility-platform/
```

Should return nothing.

**Cost Impact**: ✅ Stops storage charges

---

### Step 3: Delete S3 Bucket

**3.1 Delete the bucket:**
```bash
aws s3 rb s3://datashade-eligibility-platform --force
```

**3.2 Verify deletion:**
```bash
aws s3 ls | grep datashade-eligibility-platform
```

Should return nothing.

**Cost Impact**: ✅ Completely removes S3 costs

---

### Step 4: Delete Lambda Functions

Delete all Lambda functions used by your backend.

**4.1 List your Lambda functions:**
```bash
aws lambda list-functions --region ap-south-1 --query "Functions[?starts_with(FunctionName, 'eligibility-mvp')].FunctionName"
```

**4.2 Delete each function:**
```bash
aws lambda delete-function --function-name eligibility-mvp-profile --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-eligibility --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-scheme --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-document --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-document-processor --region ap-south-1
```

**4.3 Verify deletion:**
```bash
aws lambda list-functions --region ap-south-1 --query "Functions[?starts_with(FunctionName, 'eligibility-mvp')].FunctionName"
```

Should return empty array `[]`.

**Cost Impact**: ✅ Stops Lambda execution charges

---

### Step 5: Delete API Gateway

**5.1 Get your API ID:**
```bash
aws apigateway get-rest-apis --region ap-south-1 --query "items[?name=='eligibility-mvp-api'].id" --output text
```

**5.2 Delete the API (replace YOUR_API_ID):**
```bash
aws apigateway delete-rest-api --rest-api-id YOUR_API_ID --region ap-south-1
```

Or if you know the API ID from your .env file (csmvf1r14h):
```bash
aws apigateway delete-rest-api --rest-api-id csmvf1r14h --region ap-south-1
```

**5.3 Verify deletion:**
```bash
aws apigateway get-rest-apis --region ap-south-1 --query "items[?name=='eligibility-mvp-api']"
```

Should return empty array `[]`.

**Cost Impact**: ✅ Stops API Gateway charges

---

### Step 6: Delete DynamoDB Table

**⚠️ WARNING**: This will permanently delete all user data, profiles, schemes, and documents!

**6.1 Backup data (optional but recommended):**
```bash
aws dynamodb scan --table-name eligibility-mvp-table --region ap-south-1 > dynamodb-backup.json
```

**6.2 Delete the table:**
```bash
aws dynamodb delete-table --table-name eligibility-mvp-table --region ap-south-1
```

**6.3 Verify deletion:**
```bash
aws dynamodb list-tables --region ap-south-1 --query "TableNames[?contains(@, 'eligibility-mvp')]"
```

Should return empty array `[]`.

**Cost Impact**: ✅ Stops DynamoDB storage and request charges

---

### Step 7: Delete Cognito User Pool

**⚠️ WARNING**: This will delete all user accounts and authentication data!

**7.1 Delete the user pool:**
```bash
aws cognito-idp delete-user-pool --user-pool-id ap-south-1_VmnAr5m2B --region ap-south-1
```

**7.2 Verify deletion:**
```bash
aws cognito-idp list-user-pools --max-results 10 --region ap-south-1 --query "UserPools[?Name=='eligibility-mvp-user-pool']"
```

Should return empty array `[]`.

**Cost Impact**: ✅ Stops Cognito charges

---

### Step 8: Delete IAM Roles (Optional)

If you created custom IAM roles for Lambda functions:

**8.1 List Lambda execution roles:**
```bash
aws iam list-roles --query "Roles[?contains(RoleName, 'eligibility-mvp') || contains(RoleName, 'lambda-execution')].RoleName"
```

**8.2 For each role, detach policies first:**
```bash
aws iam list-attached-role-policies --role-name YOUR_ROLE_NAME
aws iam detach-role-policy --role-name YOUR_ROLE_NAME --policy-arn POLICY_ARN
```

**8.3 Delete the role:**
```bash
aws iam delete-role --role-name YOUR_ROLE_NAME
```

**Cost Impact**: ✅ IAM roles are free, but good for cleanup

---

### Step 9: Verify All Resources Deleted

Run these commands to ensure everything is gone:

**9.1 Check CloudFront:**
```bash
aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='DataShade Eligibility Platform']"
```

**9.2 Check S3:**
```bash
aws s3 ls | grep datashade
```

**9.3 Check Lambda:**
```bash
aws lambda list-functions --region ap-south-1 --query "Functions[?starts_with(FunctionName, 'eligibility-mvp')]"
```

**9.4 Check API Gateway:**
```bash
aws apigateway get-rest-apis --region ap-south-1 --query "items[?name=='eligibility-mvp-api']"
```

**9.5 Check DynamoDB:**
```bash
aws dynamodb list-tables --region ap-south-1 --query "TableNames[?contains(@, 'eligibility-mvp')]"
```

**9.6 Check Cognito:**
```bash
aws cognito-idp list-user-pools --max-results 10 --region ap-south-1 --query "UserPools[?Name=='eligibility-mvp-user-pool']"
```

All commands should return empty results `[]` or nothing.

---

### Step 10: Check AWS Billing Dashboard

**10.1 Via AWS Console:**
1. Go to AWS Console → Billing Dashboard
2. Click "Bills" in the left menu
3. Check current month charges
4. Verify no charges from deleted services

**10.2 Via CLI:**
```bash
aws ce get-cost-and-usage --time-period Start=2026-03-01,End=2026-03-31 --granularity MONTHLY --metrics "UnblendedCost" --group-by Type=SERVICE
```

**10.3 Set up billing alerts (optional):**
```bash
aws cloudwatch put-metric-alarm --alarm-name billing-alert --alarm-description "Alert when charges exceed $5" --metric-name EstimatedCharges --namespace AWS/Billing --statistic Maximum --period 21600 --threshold 5 --comparison-operator GreaterThanThreshold --evaluation-periods 1
```

---

## 🚀 Quick Teardown Script

I've created a script to automate the teardown process. Use with caution!

**teardown-all.bat** (Windows):

```bat
@echo off
echo ========================================
echo AWS Resource Teardown Script
echo ========================================
echo.
echo WARNING: This will DELETE ALL resources!
echo - CloudFront Distribution
echo - S3 Bucket and all files
echo - Lambda Functions
echo - API Gateway
echo - DynamoDB Table (ALL DATA LOST!)
echo - Cognito User Pool (ALL USERS LOST!)
echo.
set /p confirm="Type 'DELETE' to confirm: "
if not "%confirm%"=="DELETE" (
    echo Teardown cancelled.
    pause
    exit /b 0
)

echo.
echo Starting teardown...
echo.

echo [1/7] Deleting S3 bucket contents...
aws s3 rm s3://datashade-eligibility-platform/ --recursive
aws s3 rb s3://datashade-eligibility-platform --force
echo S3 bucket deleted.
echo.

echo [2/7] Deleting Lambda functions...
aws lambda delete-function --function-name eligibility-mvp-profile --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-eligibility --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-scheme --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-document --region ap-south-1
aws lambda delete-function --function-name eligibility-mvp-document-processor --region ap-south-1
echo Lambda functions deleted.
echo.

echo [3/7] Deleting API Gateway...
aws apigateway delete-rest-api --rest-api-id csmvf1r14h --region ap-south-1
echo API Gateway deleted.
echo.

echo [4/7] Backing up DynamoDB data...
aws dynamodb scan --table-name eligibility-mvp-table --region ap-south-1 > dynamodb-backup.json
echo Backup saved to dynamodb-backup.json
echo.

echo [5/7] Deleting DynamoDB table...
aws dynamodb delete-table --table-name eligibility-mvp-table --region ap-south-1
echo DynamoDB table deleted.
echo.

echo [6/7] Deleting Cognito User Pool...
aws cognito-idp delete-user-pool --user-pool-id ap-south-1_VmnAr5m2B --region ap-south-1
echo Cognito User Pool deleted.
echo.

echo [7/7] CloudFront Distribution...
echo NOTE: CloudFront must be disabled manually first (takes 15-20 min)
echo Run these commands manually:
echo   aws cloudfront get-distribution --id E3VARXR2SXA3P7
echo   (Disable it, wait for deployment, then delete)
echo.

echo ========================================
echo Teardown Complete!
echo ========================================
echo.
echo Remaining manual steps:
echo 1. Disable and delete CloudFront distribution E3VARXR2SXA3P7
echo 2. Check AWS Billing Dashboard to verify no charges
echo 3. Delete IAM roles if created
echo.
echo Your data backup is saved in: dynamodb-backup.json
echo.
pause
```

---

## 💰 Expected Cost After Teardown

After completing all steps:
- **S3**: $0 (deleted)
- **CloudFront**: $0 (deleted)
- **Lambda**: $0 (deleted)
- **API Gateway**: $0 (deleted)
- **DynamoDB**: $0 (deleted)
- **Cognito**: $0 (deleted)

**Total Monthly Cost**: $0

---

## 🔄 What If I Want to Redeploy Later?

If you want to bring the platform back online:

1. **Keep your code**: Make sure it's in GitHub
2. **Save the backup**: Keep `dynamodb-backup.json` if you want to restore data
3. **Follow DEPLOYMENT_GUIDE.md**: Redeploy from scratch
4. **Restore data** (optional):
   ```bash
   # After recreating DynamoDB table
   aws dynamodb batch-write-item --request-items file://dynamodb-backup.json
   ```

---

## ⏱️ Time Estimates

- **CloudFront disable + delete**: 30-40 minutes (waiting for deployment)
- **S3 deletion**: 2-5 minutes
- **Lambda deletion**: 2-3 minutes
- **API Gateway deletion**: 1 minute
- **DynamoDB deletion**: 1-2 minutes
- **Cognito deletion**: 1 minute

**Total Time**: ~45-60 minutes (mostly waiting for CloudFront)

---

## 🆘 Troubleshooting

### Error: "Distribution must be disabled before deletion"
**Solution**: Wait for CloudFront to finish deploying after disabling. Check status:
```bash
aws cloudfront get-distribution --id E3VARXR2SXA3P7 --query "Distribution.Status"
```

### Error: "Bucket not empty"
**Solution**: Delete all objects first:
```bash
aws s3 rm s3://datashade-eligibility-platform/ --recursive
```

### Error: "Resource not found"
**Solution**: Resource already deleted. Skip to next step.

### Error: "Access Denied"
**Solution**: Check your AWS credentials have admin permissions:
```bash
aws sts get-caller-identity
```

---

## 📞 Final Verification

After completing all steps, run this verification command:

```bash
echo "Checking CloudFront..." && aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='DataShade Eligibility Platform']" && echo "Checking S3..." && aws s3 ls | grep datashade && echo "Checking Lambda..." && aws lambda list-functions --region ap-south-1 --query "Functions[?starts_with(FunctionName, 'eligibility-mvp')]" && echo "Checking API Gateway..." && aws apigateway get-rest-apis --region ap-south-1 --query "items[?name=='eligibility-mvp-api']" && echo "Checking DynamoDB..." && aws dynamodb list-tables --region ap-south-1 --query "TableNames[?contains(@, 'eligibility-mvp')]" && echo "Checking Cognito..." && aws cognito-idp list-user-pools --max-results 10 --region ap-south-1 --query "UserPools[?Name=='eligibility-mvp-user-pool']" && echo "All checks complete!"
```

If all return empty results, you're good! ✅

---

## 🎉 You're All Set!

All AWS resources have been deleted and you won't be charged anymore.

**Remember**:
- Your code is safe in GitHub
- Your data backup is in `dynamodb-backup.json`
- You can redeploy anytime using DEPLOYMENT_GUIDE.md

**Stay safe and happy coding! 🚀**
