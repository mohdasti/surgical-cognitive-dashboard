#!/usr/bin/env Rscript
# Thumbnail Generator for Case Study Gallery
# Creates JPEG thumbnails from PNG gallery images

library(magick)

cat("🖼️  Generating thumbnails for case study gallery...\n")

# Create thumbs directory
dir.create("case_study/thumbs", showWarnings = FALSE, recursive = TRUE)

# List of gallery images
gallery_images <- c(
  "monitor_cards.png",
  "monitor_streams.png", 
  "monitor_probs.png",
  "monitor_alerts.png",
  "features_gt.png",
  "calibration.png",
  "prob_dists.png",
  "stability.png",
  "feat_importance.png",
  "policy_overlay.png"
)

# Function to create thumbnail
create_thumbnail <- function(input_file, output_file, width = 480, height = 270, quality = 85) {
  input_path <- file.path("case_study/images", input_file)
  output_path <- file.path("case_study/thumbs", output_file)
  
  if (!file.exists(input_path)) {
    cat("⚠️  Warning: Input file not found:", input_path, "\n")
    return(FALSE)
  }
  
  tryCatch({
    # Read image
    img <- image_read(input_path)
    
    # Resize to thumbnail dimensions
    thumb <- image_resize(img, paste0(width, "x", height, "!"))
    
    # Convert to JPEG and save
    image_write(thumb, output_path, format = "jpeg", quality = quality)
    
    cat("✅ Created thumbnail:", output_file, "\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ Error creating thumbnail for", input_file, ":", e$message, "\n")
    return(FALSE)
  })
}

# Generate thumbnails
success_count <- 0
total_count <- length(gallery_images)

for (img in gallery_images) {
  thumb_name <- paste0("thumb_", img)
  thumb_name <- gsub("\\.png$", ".jpg", thumb_name)
  
  if (create_thumbnail(img, thumb_name)) {
    success_count <- success_count + 1
  }
}

cat("\n🎉 Thumbnail generation complete!\n")
cat("✅ Successfully created:", success_count, "of", total_count, "thumbnails\n")
cat("📁 Thumbnails saved to: case_study/thumbs/\n")

if (success_count < total_count) {
  cat("⚠️  Some thumbnails failed to generate. Check the warnings above.\n")
}
