@echo off
echo ========================================
echo DataShade Frontend Deployment Script
echo ========================================
echo.

echo [1/4] Building frontend...
cd packages\frontend
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo Build completed successfully!
echo.

echo [2/4] Uploading to S3...
aws s3 sync dist/ s3://datashade-eligibility-platform/ --delete
if %errorlevel% neq 0 (
    echo ERROR: S3 upload failed!
    pause
    exit /b 1
)
echo Upload completed successfully!
echo.

echo [3/4] Invalidating CloudFront cache...
aws cloudfront create-invalidation --distribution-id E3VARXR2SXA3P7 --paths "/*"
if %errorlevel% neq 0 (
    echo WARNING: CloudFront invalidation failed (non-critical)
)
echo.

echo [4/4] Deployment complete!
echo.
echo Your website is live at:
echo https://d2kxcvdynbcdn8.cloudfront.net
echo.
echo Note: CloudFront cache invalidation may take 5-10 minutes
echo.
pause
