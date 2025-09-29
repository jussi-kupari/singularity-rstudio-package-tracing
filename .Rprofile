# R startup script for Singularity container environment
# Works with RStudio running inside container, packages outside at /project/R_libs

# Project directory (inside container this is always /project)
project_dir <- "/project"
lib_path <- "/project/R_libs"

# Create R_libs if it doesn't exist (first time setup)
if (!dir.exists(lib_path)) {
  dir.create(lib_path, recursive = TRUE)
  cat(" Created R_libs directory\n")
}

# Ensure project R library is first in path
.libPaths(c(lib_path, .libPaths()))

# Set working directory to project
if (interactive()) {
  setwd(project_dir)
}

# Source the tracking tools if available
tools_file <- file.path(project_dir, "r_tools", "package_tracker.R")
tracking_available <- file.exists(tools_file)

if (tracking_available) {
  tryCatch({
    source(tools_file)
    
    cat(" RStudio in Container | ✓ Project ready | Custom lib path active\n")
    cat(" Package tracker loaded!\n")
    cat("   install_cran('pkg')     - Install from CRAN with tracking\n")
    cat("   install_bioc('pkg')     - Install from Bioconductor with tracking\n")
    cat("   install_github('user/repo') - Install from GitHub with tracking\n")
    cat("   show_install_history()  - View installation log\n")
    cat("   generate_full_reproducibility() - Create reproducibility report\n")
    cat("\n")
    
  }, error = function(e) {
    # Tracking tools failed to load, but basic setup still works
    cat("✓ Project ready | Custom lib path active\n")
    cat("⚠️  Package tracker not loaded:", e$message, "\n")
    cat("   (Add r_tools/package_tracker.R to enable tracking)\n")
  })
} else {
  # No tracking tools, just basic setup (your original behavior)
  cat("✓ Project ready | Custom lib path active\n")
  cat("   (Add r_tools/package_tracker.R to enable install tracking)\n")
}

# Set options
options(
  repos = c(CRAN = "https://cloud.r-project.org/"),
  BioC_mirror = "https://bioconductor.org",
  download.file.method = "libcurl",
  # Helpful for container environment
  timeout = 600  # Longer timeout for slow connections
)

# Display environment info
if (interactive()) {
  cat(" Library path:", lib_path, "\n")
  cat(" R version:", paste(R.version$major, R.version$minor, sep = "."), "\n")
  
  # Count packages
  installed_pkgs <- list.files(lib_path)
  if (length(installed_pkgs) > 0) {
    cat(" Local packages:", length(installed_pkgs), "\n")
  }
  cat("\n")
}
