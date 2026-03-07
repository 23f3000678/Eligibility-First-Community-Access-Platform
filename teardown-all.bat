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
if %errorlevel% equ 0 (
    echo S3 contents deleted.
) else (
    echo WARNING: S3 content deletion failed or bucket already empty.
)
echo.

echo [2/7] Deleting S3 bucket...
aws s3 rb s3://datashade-eligibility-platform --force
if %errorlevel% equ 0 (
    echo S3 bucket deleted.
) else (
    echo WARNING: S3 bucket deletion failed or already deleted.
)
echo.

echo [3/7] Deleting Lambda functions...
aws lambda delete-function --function-name eligibility-mvp-profile --region ap-south-1 2>nul
aws lambda delete-function --function-name eligibility-mvp-eligibility --region ap-south-1 2>nul
aws lambda delete-function --function-name eligibility-mvp-scheme --region ap-south-1 2>nul
aws lambda delete-function --function-name eligibility-mvp-document --region ap-south-1 2>nul
aws lambda delete-function --function-name eligibility-mvp-document-processor --region ap-south-1 2>nul
echo Lambda functions deleted.
echo.

echo [4/7] Deleting API Gateway...
aws apigateway delete-rest-api --rest-api-id csmvf1r14h --region ap-south-1 2>nul
if %errorlevel% equ 0 (
    echo API Gateway deleted.
) else (
    echo WARNING: API Gateway deletion failed or already deleted.
)
echo.

echo [5/7] Backing up DynamoDB data...
aws dynamodb scan --table-name eligibility-mvp-table --region ap-south-1 > dynamodb-backup.json 2>nul
if %errorlevel% equ 0 (
    echo Backup saved to dynamodb-backup.json
) else (
    echo WARNING: DynamoDB backup failed or table already deleted.
)
echo.

echo [6/7] Deleting DynamoDB table...
aws dynamodb delete-table --table-name eligibility-mvp-table --region ap-south-1 2>nul
if %errorlevel% equ 0 (
    echo DynamoDB table deleted.
) else (
    echo WARNING: DynamoDB table deletion failed or already deleted.
)
echo.

echo [7/7] Deleting Cognito User Pool...
aws cognito-idp delete-user-pool --user-pool-id ap-south-1_VmnAr5m2B --region ap-south-1 2>nul
if %errorlevel% equ 0 (
    echo Cognito User Pool deleted.
) else (
    echo WARNING: Cognito deletion failed or already deleted.
)
echo.

echo ========================================
echo Teardown Complete!
echo ========================================
echo.
echo Remaining manual steps:
echo 1. Disable and delete CloudFront distribution E3VARXR2SXA3P7
echo    (CloudFront requires manual disable, wait 15-20 min, then delete)
echo.
echo To disable CloudFront:
echo   aws cloudfront get-distribution-config --id E3VARXR2SXA3P7 ^> cf-config.json
echo   (Edit cf-config.json: change "Enabled": true to "Enabled": false)
echo   aws cloudfront get-distribution --id E3VARXR2SXA3P7 --query "ETag" --output text
echo   aws cloudfront update-distribution --id E3VARXR2SXA3P7 --if-match YOUR_ETAG --distribution-config file://cf-config.json
echo   (Wait 15-20 minutes for deployment)
echo   aws cloudfront delete-distribution --id E3VARXR2SXA3P7 --if-match NEW_ETAG
echo.
echo 2. Check AWS Billing Dashboard to verify no charges
echo 3. Delete IAM roles if created (optional)
echo.
echo Your data backup is saved in: dynamodb-backup.json
echo.
echo ========================================
echo Verification Commands:
echo ========================================
echo Check remaining resources:
echo   aws s3 ls ^| findstr datashade
echo   aws lambda list-functions --region ap-south-1 --query "Functions[?starts_with(FunctionName, 'eligibility-mvp')]"
echo   aws dynamodb list-tables --region ap-south-1 --query "TableNames[?contains(@, 'eligibility-mvp')]"
echo   aws cloudfront list-distributions --query "DistributionList.Items[?Comment=='DataShade Eligibility Platform']"
echo.
pause
