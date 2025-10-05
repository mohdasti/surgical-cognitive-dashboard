# Test embed utilities functionality
cat("=== Embed Utilities Test ===\n")

# Test 1: Check if embed-check.html exists and has correct content
cat("1. Testing embed-check.html...\n")
if (file.exists("www/embed-check.html")) {
  content <- readLines("www/embed-check.html", warn = FALSE)
  if (any(grepl("window.top!==window.self", content))) {
    cat("   ✓ embed-check.html contains iframe detection script\n")
  } else {
    cat("   ✗ embed-check.html missing iframe detection script\n")
  }
  
  if (any(grepl("Top ≠ Self", content))) {
    cat("   ✓ embed-check.html contains expected text\n")
  } else {
    cat("   ✗ embed-check.html missing expected text\n")
  }
} else {
  cat("   ✗ embed-check.html not found\n")
}

# Test 2: Check if embed-test.html exists
cat("2. Testing embed-test.html...\n")
if (file.exists("www/embed-test.html")) {
  content <- readLines("www/embed-test.html", warn = FALSE)
  if (any(grepl("Embed Test Suite", content))) {
    cat("   ✓ embed-test.html contains test suite\n")
  } else {
    cat("   ✗ embed-test.html missing test suite\n")
  }
  
  if (any(grepl("checkHeaders", content))) {
    cat("   ✓ embed-test.html contains header check function\n")
  } else {
    cat("   ✗ embed-test.html missing header check function\n")
  }
} else {
  cat("   ✗ embed-test.html not found\n")
}

# Test 3: Check if header check script exists and is executable
cat("3. Testing check_headers.sh...\n")
if (file.exists("scripts/check_headers.sh")) {
  cat("   ✓ check_headers.sh exists\n")
  
  # Check if it's executable
  if (file.access("scripts/check_headers.sh", mode = 1) == 0) {
    cat("   ✓ check_headers.sh is executable\n")
  } else {
    cat("   ✗ check_headers.sh is not executable\n")
  }
  
  # Check content
  content <- readLines("scripts/check_headers.sh", warn = FALSE)
  if (any(grepl("content-security-policy|x-frame-options", content))) {
    cat("   ✓ check_headers.sh contains header check logic\n")
  } else {
    cat("   ✗ check_headers.sh missing header check logic\n")
  }
} else {
  cat("   ✗ check_headers.sh not found\n")
}

# Test 4: Check if app.R has base target
cat("4. Testing app.R base target...\n")
if (file.exists("app.R")) {
  content <- readLines("app.R", warn = FALSE)
  if (any(grepl("tags\\$base\\(target=\"_parent\"\\)", content))) {
    cat("   ✓ app.R contains base target for iframe compatibility\n")
  } else {
    cat("   ✗ app.R missing base target\n")
  }
} else {
  cat("   ✗ app.R not found\n")
}

# Test 5: Check nginx configuration
cat("5. Testing nginx configuration...\n")
if (file.exists("nginx.conf")) {
  content <- readLines("nginx.conf", warn = FALSE)
  if (any(grepl("frame-ancestors", content))) {
    cat("   ✓ nginx.conf contains frame-ancestors header\n")
  } else {
    cat("   ✗ nginx.conf missing frame-ancestors header\n")
  }
  
  if (any(grepl("X-Frame-Options.*ALLOWALL", content))) {
    cat("   ✓ nginx.conf contains X-Frame-Options ALLOWALL\n")
  } else {
    cat("   ✗ nginx.conf missing X-Frame-Options ALLOWALL\n")
  }
} else {
  cat("   ✗ nginx.conf not found\n")
}

cat("\n=== Test Commands ===\n")
cat("Local test: Rscript -e \"shiny::runApp()\" then open http://localhost:3838/embed-check.html\n")
cat("Header test: ./scripts/check_headers.sh https://your-app.com/embed-check.html\n")
cat("Full test: Open http://your-app.com/embed-test.html\n")

cat("\n=== Expected Results ===\n")
cat("Direct access: 'Top ≠ Self? No'\n")
cat("iframe access: 'Top ≠ Self? Yes'\n")
cat("Headers: Content-Security-Policy with frame-ancestors\n")

cat("\n=== Embed Utilities Test Complete ===\n")
