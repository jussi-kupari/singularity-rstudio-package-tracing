# R Environment Tools Guide

This guide covers the R environment management tools for tracking installations and ensuring reproducibility, mirroring the Python tools we created.

##  Setup

### Recommended Project Structure

```
your-r-project/
├── .Rprofile                         # R startup script
├── .Rhistory                         # R command history (auto-generated)
├── .r_install_history.json           # Installation tracking log (structured)
├── .r_install_history.txt            # Installation tracking log (human-readable)
├── install_r_packages.R              # Generated install script
├── r_reproducibility_report_*.json   # Generated reproducibility reports
├── rstudio.sif                       # Singularity container
├── rstudio.def                       # Container definition
├── run_rstudio.sh                    # RStudio launcher
├── R_libs/                           # User-installed packages
│   ├── package1/
│   ├── package2/
│   └── ...
├── r_tools/                          # R environment tools ⭐ NEW
│   ├── package_tracker.R             # Package tracking and analysis
│   └── README.md                     # This guide
├── data/                             # Your project data
├── scripts/                          # Your analysis scripts
└── results/                          # Your analysis results
```

### 1. Create the tools directory
```bash
mkdir r_tools
```

### 2. Add the tracking tools
Place the `package_tracker.R` file in `r_tools/`

### 3. Create .Rprofile in project root
Place the `.Rprofile` file in your project root (see artifact above)

### 4. Verify setup
Start R and check if tools loaded:
```r
# Should see welcome message about tracker being loaded
```

##  Interactive R Usage

### Installation Tracking (Recommended Method)

Instead of using `install.packages()` directly, use the tracking functions:

```r
# Install from CRAN (tracked)
install_cran("dplyr", "ggplot2", "tidyr")

# Install from Bioconductor (tracked)
install_bioc("DESeq2", "edgeR")

# Install from GitHub (tracked)
install_github("tidyverse/dplyr")

# Alternative: use the general function with method parameter
install_tracked("Seurat", method = "cran")
```

### View Installation History

```r
# Show all installation history
show_install_history()

# Show last 5 installations
show_install_history(recent = 5)

# Filter by method
show_install_history(method = "bioc")
```

### Package Analysis

```r
# Quick check of R versions/libraries
check_r_versions()

# Analyze all installed packages
analysis <- analyze_r_packages()

# Print summary
print_package_summary(analysis)

# Look at specific package info
analysis$manually_installed$dplyr
analysis$dependencies$rlang
```

### Generate Reproducibility Files

```r
# Generate everything at once
generate_full_reproducibility()

# Or generate components separately:

# 1. Reproducibility report (JSON)
generate_reproducibility_report()

# 2. Install script
generate_install_script()

# 3. Install script with dependencies
generate_install_script(include_dependencies = TRUE)
```

##  What Gets Tracked

### Installation Log Files

**`.r_install_history.json`** - Structured log containing:
- Timestamp of installation
- Packages requested
- Installation method (CRAN, Bioconductor, GitHub)
- R version used
- Success/failure status
- Error messages (if any)

**`.r_install_history.txt`** - Human-readable log:
```
[2025-09-29 14:30:15] ✓ cran: install_cran("dplyr", "ggplot2")
  Packages: dplyr, ggplot2
  Method: cran

[2025-09-29 14:32:20] ✓ bioc: install_bioc("DESeq2")
  Packages: DESeq2
  Method: bioc
```

### Package Analysis

The analyzer correlates:
1. **Installation history** (from `.r_install_history.json`)
2. **R command history** (from `.Rhistory`)
3. **Actual installed packages** (from `R_libs/`)
4. **Package metadata** (from DESCRIPTION files)

##  Workflow Examples

### Daily Development

```r
# Start R - tools load automatically
# .Rprofile sources package_tracker.R

# Install packages as needed
install_cran("data.table")
install_bioc("limma")
install_github("satijalab/seurat", "seurat5")

# Check what's installed
print_package_summary()

# Continue working...
```

### End of Project - Create Reproducibility Package

```r
# Generate complete reproducibility info
generate_full_reproducibility()

# Files created:
# - r_reproducibility_report_TIMESTAMP.json
# - install_r_packages.R

# View installation history
show_install_history()
```

### Recreating Environment

```bash
# Option 1: Run the generated script
Rscript install_r_packages.R

# Option 2: Source in R
source("install_r_packages.R")
```

### Migrating to New Project/Container

```r
# 1. Generate reproducibility files
generate_full_reproducibility()

# 2. Copy to new location:
#    - install_r_packages.R
#    - r_reproducibility_report_*.json

# 3. In new environment:
source("install_r_packages.R")
```

##  Comparison: Old vs New Approach

### Your Original Functions

```r
# Old approach (manual, one-time use)
info <- extract_package_info()
script <- generate_install_script(info, use_reproduce = TRUE)
```

**Limitations:**
- No tracking during installation
- Relies only on .Rhistory (can be cleared)
- Manual execution each time
- No timestamp information
- No success/failure tracking

### New Tracked Approach

```r
# New approach (automatic, continuous tracking)
install_cran("dplyr")  # Automatically tracked
show_install_history()  # See all tracked installations
generate_full_reproducibility()  # Complete report
```

**Advantages:**
-  Automatic tracking during installation
-  Persistent log (JSON + text)
-  Timestamps and metadata
-  Success/failure recording
-  Combines .Rhistory + install log + package analysis
-  Integrated into workflow
-  Similar to Python tools (consistent approach)

##  Advanced Usage

### Custom Library Paths

```r
# Analyze custom library
analysis <- analyze_r_packages(
  lib_path = "/custom/path/to/R_libs",
  rhistory_path = "/custom/.Rhistory"
)
```

### Programmatic Access

```r
# Get analysis results
analysis <- analyze_r_packages()

# Access manually installed packages
manual_pkgs <- names(analysis$manually_installed)

# Access dependencies
dep_pkgs <- names(analysis$dependencies)

# Get reproducible install commands
install_cmds <- sapply(analysis$manually_installed, 
                      function(x) x$ReproduceInstall)
```

### Generate Different Script Types

```r
# Just manually installed packages (default)
generate_install_script(
  use_reproduce = TRUE,
  include_dependencies = FALSE,
  output_file = "install_manual.R"
)

# Include all dependencies
generate_install_script(
  use_reproduce = TRUE,
  include_dependencies = TRUE,
  output_file = "install_all.R"
)

# Use original commands (not recommended for reproducibility)
generate_install_script(
  use_reproduce = FALSE,
  output_file = "install_original.R"
)
```

##  Troubleshooting

### Tools Don't Load

**Problem:** No message about tracker being loaded when starting R

**Solutions:**
1. Check `.Rprofile` exists in project root:
   ```bash
   ls -la .Rprofile
   ```

2. Check `r_tools/package_tracker.R` exists:
   ```bash
   ls -la r_tools/package_tracker.R
   ```

3. Manually source the tools:
   ```r
   source("r_tools/package_tracker.R")
   ```

4. Check for errors in `.Rprofile`:
   ```r
   # Start R with --vanilla to skip .Rprofile
   R --vanilla
   
   # Then manually source to see errors
   source(".Rprofile")
   ```

### Installation Tracking Not Working

**Problem:** Installations not appearing in `.r_install_history.json`

**Solutions:**
1. Make sure you're using the tracking functions:
   ```r
   # Wrong (not tracked):
   install.packages("dplyr")
   
   # Right (tracked):
   install_cran("dplyr")
   ```

2. Check file permissions:
   ```bash
   ls -la .r_install_history.json
   # Should be writable
   ```

3. Check if directory is writable:
   ```r
   file.access(".", 2) == 0  # Should return TRUE
   ```

### Missing Package Dependencies

**Problem:** `jsonlite` package not found

**Solution:**
```r
# Install required dependencies
install.packages("jsonlite", lib = "R_libs")
```

### R_libs Not Being Used

**Problem:** Packages installing to system library instead of `R_libs/`

**Solution:**
1. Check library paths:
   ```r
   .libPaths()
   # R_libs should be first
   ```

2. Verify `.Rprofile` is setting paths correctly

3. Restart R session after creating `.Rprofile`

### Reproducibility Script Fails

**Problem:** Generated `install_r_packages.R` fails to run

**Solutions:**
1. Check R version compatibility:
   ```r
   # In reproducibility report, check r_version
   # Compare with current R version
   R.version
   ```

2. Check package availability:
   - CRAN packages should work with version pinning
   - Bioconductor packages may need specific BioC version
   - GitHub packages may have moved/been deleted

3. Run with error handling:
   ```r
   # Add tryCatch to install script
   tryCatch(
     source("install_r_packages.R"),
     error = function(e) message("Error: ", e$message)
   )
   ```

##  Integration with Singularity

### Update Your Container Definition

Add to your `rstudio.def`:

```bash
%post
    # Install required packages for tracking
    R -e "install.packages(c('jsonlite'), repos='https://cloud.r-project.org/')"

%environment
    export R_LIBS_USER="/project/R_libs"
```

### Update Launch Scripts

If you have `run_rstudio.sh`, ensure it binds the necessary directories:

```bash
#!/bin/bash
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure R_libs exists
mkdir -p "${PROJECT_DIR}/R_libs"

singularity exec \
    --bind "${PROJECT_DIR}:/project" \
    --bind "${PROJECT_DIR}/R_libs:/project/R_libs" \
    "${PROJECT_DIR}/rstudio.sif" \
    rstudio "$@"
```

### Set R Environment in Container

Your `.Rprofile` will automatically:
- Set library paths to use `R_libs/`
- Load tracking tools
- Configure CRAN/Bioconductor mirrors

##  Migrating from Your Original Functions

If you have existing code using `extract_package_info()` and `generate_install_script()`, here's how to transition:

### One-Time Migration

```r
# 1. Source the new tools
source("r_tools/package_tracker.R")

# 2. Analyze existing packages (works with both approaches)
analysis <- analyze_r_packages()

# 3. Generate reproducibility files with new system
generate_full_reproducibility()

# 4. From now on, use tracked installations
install_cran("new_package")  # Automatically tracked
```

### Keep Both Systems

You can keep your original functions and add the new tracking system:

```r
# Load new tracking tools
source("r_tools/package_tracker.R")

# Your original functions still work
source("your_original_functions.R")

# Use new tools for ongoing work
install_cran("package")  # New: tracked installation

# Use original for retrospective analysis
info <- extract_package_info()  # Original: analyze existing
```

### Gradual Transition

```r
# Week 1: Just add tracking to new installations
install_cran("new_package")  # Use new function

# Week 2: Check tracking is working
show_install_history()

# Week 3: Generate reproducibility files
generate_full_reproducibility()

# Week 4: Fully migrated!
# All installations tracked
# Regular reproducibility reports
```

##  Best Practices

### Installation

1. **Always use tracking functions for new packages:**
   ```r
   install_cran("package_name")    # Not install.packages()
   install_bioc("package_name")    # Not BiocManager::install()
   install_github("user/repo")     # Track GitHub installs
   ```

2. **Document special cases:**
   ```r
   # If you must use install.packages() directly, document why:
   # (Example: installing from local file)
   install.packages("package_1.0.tar.gz", repos = NULL)
   # Then manually log it
   # install_cran("package")  # Would normally use this
   ```

3. **Regular reproducibility checks:**
   ```r
   # At project milestones
   generate_full_reproducibility()
   
   # Before major changes
   print_package_summary()
   ```

### Version Control

**Commit to Git:**
```gitignore
.Rprofile
r_tools/
install_r_packages.R          # Final version
r_reproducibility_report_*.json  # Final reports (optional)
```

**Ignore in Git:**
```gitignore
.Rhistory
.r_install_history.json
.r_install_history.txt
R_libs/
.RData
.Rproj.user
```

### Documentation

In your project README.md:
```markdown
## R Environment

This project uses R [version] with packages in `R_libs/`.

### Setup
```r
# Reproduce environment
source("install_r_packages.R")
```

### Installing New Packages
```r
# Use tracking functions
install_cran("package_name")
install_bioc("bioc_package")
```

### Regenerate Reproducibility Files
```r
generate_full_reproducibility()
```
```

### Collaboration

When sharing with collaborators:

1. **Share reproducibility files:**
   ```
   install_r_packages.R
   r_reproducibility_report_*.json
   ```

2. **Document R version requirements:**
   ```r
   # Check R version in reproducibility report
   # Recommend using same major.minor version
   ```

3. **Include setup instructions:**
   ```markdown
   1. Clone repository
   2. Run: Rscript install_r_packages.R
   3. Open R/RStudio in project directory
   4. .Rprofile will configure environment automatically
   ```

##  Comparison with Python Tools

Both Python and R tools now follow the same philosophy:

| Feature | Python | R |
|---------|--------|---|
| **Tracking Function** | `install()` | `install_cran()` |
| **History Log** | `.python_install_history.json` | `.r_install_history.json` |
| **Package Analysis** | `quick_summary()` | `print_package_summary()` |
| **Reproducibility** | `generate_reproducibility()` | `generate_full_reproducibility()` |
| **Install Script** | `requirements.txt` | `install_r_packages.R` |
| **Startup File** | `.pythonrc` | `.Rprofile` |
| **Package Directory** | `python_libs/` | `R_libs/` |
| **Tools Directory** | `python_tools/` | `r_tools/` |

This consistency makes it easy to work with both languages in the same project!

##  Reference

### Main Functions

#### Installation
- `install_cran(packages, ...)` - Install from CRAN with tracking
- `install_bioc(packages, ...)` - Install from Bioconductor with tracking
- `install_github(packages, ...)` - Install from GitHub with tracking
- `install_tracked(packages, method, ...)` - General installation function

#### History
- `show_install_history(recent, method)` - Display installation history
- `save_install_log(log_entry, project_dir)` - Save installation log (internal)

#### Analysis
- `analyze_r_packages(lib_path, rhistory_path)` - Analyze installed packages
- `print_package_summary(analysis)` - Print package summary
- `check_r_versions(lib_base)` - Check R library installations

#### Reproducibility
- `generate_reproducibility_report(output_file)` - Generate JSON report
- `generate_install_script(...)` - Generate installation script
- `generate_full_reproducibility()` - Complete workflow

### File Locations

- **Tools:** `r_tools/package_tracker.R`
- **Startup:** `.Rprofile` (project root)
- **Logs:** `.r_install_history.{json,txt}` (project root)
- **Packages:** `R_libs/` (project root)
- **Reports:** `r_reproducibility_report_*.json` (project root)
- **Scripts:** `install_r_packages.R` (project root)

### Common Workflows

**New Project Setup:**
```r
# 1. Create .Rprofile and r_tools/ structure
# 2. Start R (tools load automatically)
# 3. Install packages with tracking
install_cran("tidyverse")
```

**Before Submission/Archiving:**
```r
generate_full_reproducibility()
# Commit: install_r_packages.R, r_reproducibility_report_*.json
```

**Reproducing Environment:**
```bash
Rscript install_r_packages.R
```

**Regular Maintenance:**
```r
# Weekly: Check what's installed
print_package_summary()

# Monthly: Update reproducibility files
generate_full_reproducibility()
```

##  Summary

The R environment tools provide:

1.  **Automatic tracking** of package installations
2.  **Persistent logs** in JSON and text formats
3.  **Package analysis** correlating history with actual packages
4.  **Reproducibility reports** with complete environment info
5.  **Install scripts** for environment recreation
6.  **Seamless integration** via `.Rprofile`
7.  **Consistency** with Python tools approach

Start using the tracking functions today, and your R environment will be reproducible and well-documented!
# Container Rebuild Guide

How to use tracked packages to rebuild your Singularity container with packages baked in.

##  The Problem

You've been installing packages to `R_libs/` outside the container. Now you want to:
1. Rebuild the container
2. Include some/all packages **inside** the container
3. Use actual R commands (not tracking wrappers)

##  The Solution

The tracking system now records **both**:
- **Tracking command**: `install_tracked(packages = "dplyr", method = "cran")`
- **Actual R command**: `install.packages("dplyr")`

The actual R commands work without the tracking system and can be used in container builds.

##  What's Recorded

When you run:
```r
install_cran("dplyr", "ggplot2")
```

The system records:
```json
{
  "command": "install_tracked(packages = c(\"dplyr\", \"ggplot2\"), method = \"cran\")",
  "actual_command": "install.packages(c(\"dplyr\", \"ggplot2\"))",
  "method": "cran",
  "packages": ["dplyr", "ggplot2"]
}
```

##  Workflows

### Workflow 1: Generate Script for Current Packages

```r
# Generate script with actual R commands (no tracking wrappers)
generate_container_install_script(
  include_dependencies = FALSE,  # Only manually installed
  output_file = "install_for_container.R",
  format = "r_script"
)
```

**Output (`install_for_container.R`):**
```r
#!/usr/bin/env Rscript
# R Package Installation Script for Container
# Generated: 2025-09-29 15:30:00

# Note: This script uses actual R commands, not tracking wrappers
# Suitable for use in Singularity container %post section

cat('Installing packages...\n')

install.packages("dplyr")
install.packages(c("ggplot2", "tidyr"))
BiocManager::install("DESeq2")
remotes::install_github("satijalab/seurat@seurat5")

cat('Installation complete!\n')
```

### Workflow 2: Generate for Singularity %post

```r
# Generate in Singularity format
generate_container_install_script(
  include_dependencies = FALSE,
  output_file = "singularity_packages.txt",
  format = "singularity_post"
)
```

**Output (`singularity_packages.txt`):**
```bash
# Add these lines to your Singularity definition %post section
# Generated: 2025-09-29 15:30:00

# Package installations
    R -e "install.packages('dplyr')"
    R -e "install.packages(c('ggplot2', 'tidyr'))"
    R -e "BiocManager::install('DESeq2')"
    R -e "remotes::install_github('satijalab/seurat@seurat5')"
```

### Workflow 3: Inspect Package Commands

```r
# Analyze packages
analysis <- analyze_r_packages()

# Look at a specific package
pkg <- analysis$manually_installed$dplyr

# See both commands
pkg$InstallCommandUsed      # Tracking wrapper
pkg$ActualInstallCommand    # Actual R command
pkg$ReproduceInstall        # Version-pinned command

# Example output:
# $InstallCommandUsed
# [1] "install_tracked(packages = \"dplyr\", method = \"cran\")"
#
# $ActualInstallCommand
# [1] "install.packages(\"dplyr\")"
#
# $ReproduceInstall
# [1] "remotes::install_version(\"dplyr\", version = \"1.1.3\")"
```

## ️ Complete Container Rebuild Process

### Step 1: Generate Installation Scripts

```r
# In RStudio (in container with your packages)

# Option A: R script format (can be run directly)
generate_container_install_script(
  output_file = "install_for_container.R",
  format = "r_script"
)

# Option B: Singularity format (copy-paste into .def)
generate_container_install_script(
  output_file = "singularity_packages.txt",
  format = "singularity_post"
)
```

### Step 2: Update Container Definition

**Option A: Use %files and Rscript**

```bash
# rstudio.def
Bootstrap: docker
From: rocker/tidyverse:latest

%files
    install_for_container.R /install_for_container.R

%post
    # System dependencies
    apt-get update && apt-get install -y ...
    
    # Base R packages
    R -e "install.packages('remotes')"
    R -e "install.packages('jsonlite')"
    R -e "install.packages('Seurat')"
    
    # Install packages from R_libs
    Rscript /install_for_container.R
    
    # Clean up
    apt-get clean
    rm -rf /var/lib/apt/lists/*
```

**Option B: Copy commands into %post**

```bash
# rstudio.def
Bootstrap: docker
From: rocker/tidyverse:latest

%post
    # System dependencies
    apt-get update && apt-get install -y ...
    
    # Base R packages
    R -e "install.packages('remotes')"
    R -e "install.packages('jsonlite')"
    R -e "install.packages('Seurat')"
    
    # Packages from your R_libs (paste from singularity_packages.txt)
    R -e "install.packages('dplyr')"
    R -e "install.packages(c('ggplot2', 'tidyr'))"
    R -e "BiocManager::install('DESeq2')"
    R -e "remotes::install_github('satijalab/seurat@seurat5')"
    
    # Clean up
    apt-get clean
    rm -rf /var/lib/apt/lists/*
```

### Step 3: Build Container

```bash
# Build new container
sudo singularity build rstudio_with_packages.sif rstudio.def

# Test it
singularity exec rstudio_with_packages.sif R -e "library(dplyr); packageVersion('dplyr')"
```

### Step 4: Clean R_libs (Optional)

Since packages are now in container:

```bash
# Option A: Remove everything from R_libs
rm -rf R_libs/*

# Option B: Keep R_libs for new packages
# Leave as-is, can still install additional packages there
```

##  Different Scenarios

### Scenario 1: Bake Everything In

```r
# Include all packages (manual + dependencies)
generate_container_install_script(
  include_dependencies = TRUE,
  output_file = "install_all.R"
)
```

Use this when:
-  Starting a new project
-  Finalizing a project for archival
-  Sharing container with others

### Scenario 2: Bake Only Essential Packages

```r
# Only manually installed (not dependencies)
generate_container_install_script(
  include_dependencies = FALSE,
  output_file = "install_manual.R"
)
```

Use this when:
-  Container will still use R_libs
-  Want flexibility to update dependencies
-  Container should stay smaller

### Scenario 3: Selective Package Inclusion

```r
# Analyze first
analysis <- analyze_r_packages()

# Choose which packages to include
essential_packages <- c("Seurat", "monocle3", "destiny")

# Get their install commands
essential_cmds <- lapply(essential_packages, function(pkg) {
  if (pkg %in% names(analysis$manually_installed)) {
    analysis$manually_installed[[pkg]]$ActualInstallCommand
  } else {
    NULL
  }
})

essential_cmds <- Filter(Negate(is.null), essential_cmds)

# Write custom script
writeLines(c(
  "#!/usr/bin/env Rscript",
  "# Essential packages for container",
  "",
  unlist(essential_cmds)
), "install_essential.R")
```

Use this when:
-  Some packages are slow to install
-  Some packages need specific versions in container
-  Want fine control over what goes in container

##  Example: Complete Rebuild

Let's say you've been developing for 3 months with 50 packages in R_libs.

```r
# 1. Check what you have
analysis <- analyze_r_packages()
print_package_summary(analysis)
# Manually installed: 15
# Dependencies: 35

# 2. Generate scripts
generate_container_install_script(
  include_dependencies = FALSE,
  output_file = "install_for_container.R"
)

generate_container_install_script(
  include_dependencies = FALSE,
  output_file = "singularity_packages.txt",
  format = "singularity_post"
)

# 3. Review the commands
readLines("singularity_packages.txt")

# 4. Update rstudio.def (on host)
# Add lines from singularity_packages.txt to %post
```

```bash
# 5. Build new container (on host)
sudo singularity build rstudio_v2.sif rstudio.def

# 6. Test new container
singularity exec rstudio_v2.sif R -e "installed.packages()[,c('Package','Version')]"

# 7. Backup old R_libs
mv R_libs R_libs_backup

# 8. Start fresh (or keep for additional packages)
mkdir R_libs

# 9. Use new container
# Update run_rstudio.sh to use rstudio_v2.sif
```

##  Comparing Commands

### What Gets Generated

For each tracked installation, you get multiple command options:

**Example Package: dplyr**

```r
analysis$manually_installed$dplyr

# $InstallCommandUsed (what you typed with tracking)
# "install_cran(\"dplyr\")"

# $ActualInstallCommand (actual R command)
# "install.packages(\"dplyr\")"

# $ReproduceInstall (version-pinned for exact reproduction)
# "remotes::install_version(\"dplyr\", version = \"1.1.3\")"
```

**For Container Builds, Use:**
- **Most cases**: `ActualInstallCommand` - simple, standard R commands
- **Exact reproduction**: `ReproduceInstall` - version-pinned
- **Latest versions**: Write your own based on package name

### Manual vs Automatic

**Manual Selection:**
```r
# Get specific packages
my_pkgs <- c("Seurat", "monocle3")
cmds <- sapply(my_pkgs, function(p) {
  analysis$manually_installed[[p]]$ActualInstallCommand
})
```

**Automatic (all packages):**
```r
generate_container_install_script()
```

## ⚠️ Important Notes

### 1. Version Pinning

The `ActualInstallCommand` installs the **latest version**:
```r
install.packages("dplyr")  # Gets latest
```

The `ReproduceInstall` installs the **exact version**:
```r
remotes::install_version("dplyr", version = "1.1.3")  # Gets 1.1.3
```

Choose based on your needs:
- Latest: Faster, gets updates
- Pinned: Exact reproduction, more stable

### 2. GitHub Packages

For GitHub packages, the actual command includes the commit/tag:
```r
# From tracking:
install_github("satijalab/seurat@seurat5")

# Actual command:
remotes::install_github("satijalab/seurat@seurat5")
```

### 3. Bioconductor

BiocManager must be installed first:
```bash
# In %post:
R -e "install.packages('BiocManager')"
R -e "BiocManager::install('DESeq2')"
```

### 4. Dependencies

System dependencies still needed:
```bash
# rstudio.def %post:
apt-get install -y libhdf5-dev libgdal-dev ...
```

R package dependencies are auto-installed by R.

##  Best Practices

### When to Rebuild Container

**Good reasons:**
-  Finalizing project for publication
-  Sharing with collaborators
-  Archiving for long-term storage
-  Every 6-12 months for stability
-  When R_libs gets too large (>100 packages)

**Not necessary:**
-  After every package install
-  During active development
-  When R_libs system works fine

### Container Philosophy

**Bake in container:**
- Core analysis packages (Seurat, Monocle, etc.)
- Stable, mature packages
- Packages used across projects

**Keep in R_libs:**
- Experimental packages
- Frequently updated packages  
- Project-specific packages
- Development versions

### Documentation

After rebuilding, document:
```markdown
## Container Rebuild - 2025-09-29

### Packages Added
- dplyr 1.1.3
- ggplot2 3.4.4
- DESeq2 1.38.0
- Seurat 5.0.0

### Build Command
```bash
sudo singularity build rstudio_v2.sif rstudio.def
```

### Generated From
```r
generate_container_install_script(
  output_file = "install_for_container.R"
)
```
```

##  Summary

The tracking system now provides **actual R commands** suitable for container builds:

 `ActualInstallCommand` - Standard R commands without tracking wrappers
 `generate_container_install_script()` - Auto-generate install scripts
 Two formats: R script or Singularity %post
 Full or selective package inclusion
 Works independently of tracking system

You can now easily move packages from `R_libs/` into your container!
# Command Comparison Quick Reference

##  Three Types of Commands

For every tracked installation, the system records three types of commands:

### 1. Tracking Command (`command`)
What you actually typed with the tracking wrapper.

**Example:**
```r
install_cran("dplyr", "ggplot2")
```
**Recorded as:**
```
install_tracked(packages = c("dplyr", "ggplot2"), method = "cran")
```

**Used for:**
- Debugging tracking system
- Understanding how package was installed

### 2. Actual R Command (`actual_command`) ⭐ NEW
Standard R command without tracking wrapper - works anywhere.

**Example:**
```r
install_cran("dplyr", "ggplot2")
```
**Recorded as:**
```r
install.packages(c("dplyr", "ggplot2"))
```

**Used for:**
-  Singularity container %post sections
-  Sharing with colleagues without tracking system
-  Standalone R scripts
-  Docker/Podman containers
-  CI/CD pipelines

### 3. Reproduce Command (`ReproduceInstall`)
Version-pinned command for exact reproduction.

**Example:**
```r
install_cran("dplyr")
# (version 1.1.3 gets installed)
```
**Generated as:**
```r
remotes::install_version("dplyr", version = "1.1.3")
```

**Used for:**
-  Exact environment reproduction
-  Long-term reproducibility
-  Publication archives

##  Real Examples

### CRAN Package

```r
# What you type:
install_cran("data.table")

# Tracking command:
install_tracked(packages = "data.table", method = "cran")

# Actual command (works anywhere):
install.packages("data.table")

# Reproduce command (exact version):
remotes::install_version("data.table", version = "1.14.8")
```

### Bioconductor Package

```r
# What you type:
install_bioc("DESeq2")

# Tracking command:
install_tracked(packages = "DESeq2", method = "bioc")

# Actual command (works anywhere):
BiocManager::install("DESeq2")

# Reproduce command (exact version):
BiocManager::install("DESeq2") # version: 1.38.0
```

### GitHub Package

```r
# What you type:
install_github("satijalab/seurat@seurat5")

# Tracking command:
install_tracked(packages = "satijalab/seurat@seurat5", method = "github")

# Actual command (works anywhere):
remotes::install_github("satijalab/seurat@seurat5")

# Reproduce command (exact commit):
remotes::install_github("satijalab/seurat@seurat5")
```

### Multiple Packages

```r
# What you type:
install_cran("dplyr", "ggplot2", "tidyr")

# Tracking
