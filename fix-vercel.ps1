# DEPLOMAT Vercel Fix Script
Write-Host "🔧 Fixing DEPLOMAT for Vercel deployment..." -ForegroundColor Cyan

# 1. Delete problematic files
Write-Host "🗑️  Removing Vite/React files..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Remove-Item -Recurse -Force node_modules
    Write-Host "  ✅ Removed node_modules" -ForegroundColor Green
}
if (Test-Path "package-lock.json") {
    Remove-Item -Force package-lock.json
    Write-Host "  ✅ Removed package-lock.json" -ForegroundColor Green
}
if (Test-Path "vite.config.js") {
    Remove-Item -Force vite.config.js
    Write-Host "  ✅ Removed vite.config.js" -ForegroundColor Green
}
if (Test-Path "dist") {
    Remove-Item -Recurse -Force dist
    Write-Host "  ✅ Removed dist folder" -ForegroundColor Green
}

# 2. Rename files to .html
Write-Host "📝 Renaming files to .html..." -ForegroundColor Yellow

# List of files to rename
$filesToRename = @(
    "index", 
    "registration", 
    "event-0", "event-1", "event-2", "event-3", 
    "event-4", "event-5", "event-6", "event-7", 
    "event-8", "event-9", "event-10", "event-11"
)

foreach ($file in $filesToRename) {
    if (Test-Path $file) {
        Rename-Item -Path $file -NewName "$file.html" -ErrorAction SilentlyContinue
        Write-Host "  ✅ Renamed: $file → $file.html" -ForegroundColor Green
    }
}

# 3. Check if registration file exists with .html
if (Test-Path "registration.html") {
    Write-Host "  ✅ registration.html exists" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Warning: registration.html not found" -ForegroundColor Yellow
}

# 4. Create minimal package.json
Write-Host "📦 Creating package.json..." -ForegroundColor Yellow
@"
{
  "name": "deplomat-fest",
  "version": "1.0.0",
  "description": "DEPLOMAT Event Registration System"
}
"@ | Out-File -FilePath "package.json" -Encoding UTF8
Write-Host "  ✅ Created package.json" -ForegroundColor Green

# 5. Create vercel.json for static deployment
Write-Host "⚙️  Creating vercel.json..." -ForegroundColor Yellow
@"
{
  "version": 2,
  "builds": [
    {
      "src": "*.html",
      "use": "@vercel/static"
    },
    {
      "src": "*.css",
      "use": "@vercel/static"
    },
    {
      "src": "public/**",
      "use": "@vercel/static"
    }
  ],
  "routes": [
    {
      "src": "/",
      "dest": "/index.html"
    },
    {
      "src": "/registration",
      "dest": "/registration.html"
    },
    {
      "src": "/event-:id",
      "dest": "/event-:id.html"
    },
    {
      "src": "/(.*)",
      "dest": "/$1"
    }
  ]
}
"@ | Out-File -FilePath "vercel.json" -Encoding UTF8
Write-Host "  ✅ Created vercel.json" -ForegroundColor Green

# 6. Create .vercelignore to prevent build issues
Write-Host "📄 Creating .vercelignore..." -ForegroundColor Yellow
@"
node_modules/
dist/
.git/
*.log
.DS_Store
"@ | Out-File -FilePath ".vercelignore" -Encoding UTF8
Write-Host "  ✅ Created .vercelignore" -ForegroundColor Green

Write-Host ""
Write-Host "✅ Done! Your project is ready for Vercel deployment." -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Cyan
Write-Host "1. git add ." -ForegroundColor White
Write-Host "2. git commit -m 'Fix: Convert to static site for Vercel'" -ForegroundColor White
Write-Host "3. git push origin main" -ForegroundColor White
Write-Host "4. Wait for Vercel to auto-deploy" -ForegroundColor White