# R Container Environment Setup Guide

Guide for running RStudio in Singularity container with external package management and tracking.

## ️ Architecture Overview

```
Host System (your project directory)
├── .Rprofile                          # Loaded by R in container
├── .r_install_history.json            # Installation log
├── install_local_packages.R           # Generated install script
├── r_reproducibility_report_*.json    # Reproducibility reports
├── rstudio.sif                        # Container image
├── rstudio.def                        # Container definition
├── run_rstudio.sh                     # Launch script
├── R_libs/                            # PACKAGES LIVE HERE (outside container)
│   ├── dplyr/
│   ├── ggplot2/
│   └── ...
├── r_tools/                           # Tracking tools (outside container)
│   ├── package_tracker.R
│   └── README.md
└── your_work/
    ├── data/
    ├── scripts/
    └── results/

Singularity Container (rstudio.sif)
├── R + RStudio                        # Inside container
├── tidyverse                          # Inside container  
├── Seurat                             # Inside container
├── jsonlite                           # Inside container (for tracking)
└── remotes                            # Inside container (for GitHub installs)

When container runs:
├── /project → bound to your project directory
├── /project/R_libs → accessible to R in container
└── R sees packages from both:
    1. Container libraries (tidyverse, Seurat)
    2. /project/R_libs (your extra packages)
```

##  Understanding the Setup

### What's Inside the Container
-  Base R + RStudio Server
-  tidyverse (pre-installed)
-  Seurat (pre-installed)
-  System dependencies (GDAL, HDF5, etc.)
-  jsonlite (for tracking system)
-  remotes (for GitHub installs)

### What's Outside the Container
-  Your project files
-  Extra R packages (in `R_libs/`)
-  Package tracking logs
-  Tracking tools (`r_tools/`)
-  `.Rprofile` configuration

### Why This Setup?
1. **Container stays small** - Only base packages inside
2. **Packages persist** - `R_libs/` lives on host, survives container rebuilds
3. **Easy updates** - Rebuild container without losing packages
4. **Portable** - Move `R_libs/` between projects or machines
5. **Tracked** - Know exactly what you installed and when

##  Project Structure

```
your-project/
├── .Rprofile                       # Container-optimized startup script
├── .Rhistory                       # R command history
├── .r_install_history.json         # Installation tracking log
├── .r_install_history.txt          # Human-readable log
├── install_local_packages.R        # Generated install script
├── r_reproducibility_report_*.json # Reproducibility reports
├── rstudio.sif                     # Your container
├── rstudio.def                     # Container recipe
├── run_rstudio.sh                  # Launch script
├── project.Rproj                   # RStudio project (optional)
├── R_libs/                         # User packages (OUTSIDE container)
│   ├── package1/
│   ├── package2/
│   └── ...
├── r_tools/                        # Tracking tools (OUTSIDE container)
│   ├── package_tracker.R
│   └── README.md
├── data/
├── scripts/
└── results/
```

##  Initial Setup

### 1. Create Project Structure

```bash
# Your project root
cd /path/to/your/project

# Create directories
mkdir -p R_libs r_tools

# Add files
# - .Rprofile (from artifact above)
# - r_tools/package_tracker.R (from previous artifact)
# - Update rstudio.def (from artifact above)
```

### 2. Build Container (if needed)

```bash
# Build new container with jsonlite support
sudo singularity build rstudio.sif rstudio.def

# Or rebuild existing container
sudo singularity build --force rstudio.sif rstudio.def
```

### 3. Create/Update Launch Script

```bash
#!/bin/bash
# run_rstudio.sh

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT=$(shuf -i 8000-9000 -n 1)

echo "Starting RStudio Server in container..."
echo "Project directory: ${PROJECT_DIR}"
echo "Port: ${PORT}"

# Create R_libs if it doesn't exist
mkdir -p "${PROJECT_DIR}/R_libs"

# Launch container with RStudio Server
singularity exec \
    --bind "${PROJECT_DIR}:/project" \
    "${PROJECT_DIR}/rstudio.sif" \
    rserver --www-port=${PORT} \
            --auth-none=1 \
            --www-address=0.0.0.0 \
            --server-user=$(whoami)

echo "RStudio available at: http://localhost:${PORT}"
```

### 4. Test Setup

```bash
# Launch RStudio
./run_rstudio.sh

# In RStudio (running in container):
# You should see:
#  RStudio in Container | ✓ Project ready | Custom lib path active
#  Package tracker loaded!

# Test tracking
install_cran("praise")

# Check it worked
show_install_history()
```

##  Daily Workflow

### Starting RStudio

```bash
# Launch container with RStudio
./run_rstudio.sh

# Open browser to the URL shown
# RStudio opens with:
#   - Working directory: /project
#   - Library path: /project/R_libs first
#   - Tracking tools loaded
```

### Installing Packages (Tracked)

```r
# Install from CRAN (tracked)
install_cran("data.table", "dtplyr")

# Install from Bioconductor (tracked)
install_bioc("DESeq2", "edgeR")

# Install from GitHub (tracked)
install_github("satijalab/seurat", "seurat5")

# Check what you installed
show_install_history()
show_install_history(recent = 5)
```

### Installing Packages (Old Way - Still Works)

```r
# Still works, but NOT tracked:
install.packages("dplyr", lib = "/project/R_libs")

# To track existing installation, manually use:
# generate_full_reproducibility()
```

### Checking Your Environment

```r
# See all installed packages
print_package_summary()

# Check library paths
.libPaths()
# [1] "/project/R_libs"
# [2] "/usr/local/lib/R/site-library"  # Container packages

# List packages in R_libs
list.files("/project/R_libs")
```

##  Reproducibility Workflows

### End of Analysis - Generate Reports

```r
# Generate complete reproducibility package
generate_full_reproducibility()

# This creates:
# - r_reproducibility_report_TIMESTAMP.json (detailed info)
# - install_local_packages.R (installation script)

# Check what was created
list.files(pattern = "r_reproducibility|install_local")
```

### Sharing Your Work

**Option 1: Share installation script**
```bash
# Share with collaborator
# They run in their container:
Rscript install_local_packages.R
```

**Option 2: Rebuild container with packages baked in**
```bash
# 1. Generate install script
```
```r
generate_install_script(
  use_reproduce = TRUE,
  include_dependencies = FALSE,
  output_file = "install_local_packages.R"
)
```
```bash
# 2. Update rstudio.def:
#    Uncomment %files section to copy script into container
#    Uncomment Rscript line in %post

# 3. Rebuild container
sudo singularity build --force rstudio.sif rstudio.def

# Now packages are baked into container!
# But you can still add more to R_libs/
```

### Starting Fresh Project with Same Packages

```bash
# In new project directory
# 1. Copy files
cp /old/project/install_local_packages.R .
cp /old/project/rstudio.sif .

# 2. Run installation script inside container
singularity exec rstudio.sif Rscript install_local_packages.R

# 3. Done! Same packages installed
```

##  Advanced Usage

### Inspecting What's in Container vs R_libs

```r
# Packages in container
container_pkgs <- installed.packages(lib.loc = "/usr/local/lib/R/site-library")
container_pkgs[, "Package"]

# Packages in R_libs (your additions)
rlibs_pkgs <- installed.packages(lib.loc = "/project/R_libs")
rlibs_pkgs[, "Package"]

# All available packages
all_pkgs <- installed.packages()
nrow(all_pkgs)
```

### Moving Packages into Container

```r
# 1. Generate install script for packages you want in container
analysis <- analyze_r_packages()

# Get specific packages
desired_pkgs <- c("Seurat", "monocle3", "velocyto.R")

# Create filtered install script
# ... (filter your analysis manually)

# 2. Update rstudio.def %post section:
# R -e "install.packages('package1', repos='...')"
# R -e "install.packages('package2', repos='...')"

# 3. Rebuild container
```

### Checking Package Sources

```r
analysis <- analyze_r_packages()

# CRAN packages
cran_pkgs <- Filter(function(x) {
  !is.null(x$Repository) && x$Repository == "CRAN"
}, analysis$manually_installed)

# Bioconductor packages
bioc_pkgs <- Filter(function(x) {
  !is.null(x$Repository) && grepl("BioC", x$Repository)
}, analysis$manually_installed)

# GitHub packages
github_pkgs <- Filter(function(x) {
  !is.null(x$RemoteType) && x$RemoteType == "github"
}, analysis$manually_installed)
```

##  Troubleshooting

### Tracking Tools Not Loading

**Symptom:** Only see "✓ Project ready" but no " Package tracker loaded!"

**Solution:**
```bash
# Check files exist on host
ls -la r_tools/package_tracker.R
ls -la .Rprofile

# Inside container, check binding
singularity exec rstudio.sif ls -la /project/r_tools/

# Verify jsonlite installed in container
singularity exec rstudio.sif R -e "requireNamespace('jsonlite')"

# If jsonlite missing, rebuild container with updated .def
```

### Packages Installing to Wrong Location

**Symptom:** Packages go to container library instead of `/project/R_libs`

**Solution:**
```r
# Check library paths
.libPaths()
# Should show: [1] "/project/R_libs" ...

# If not, check .Rprofile loaded
file.exists("/project/.Rprofile")

# Manually set if needed
.libPaths(c("/project/R_libs", .libPaths()))
```

### Permission Issues

**Symptom:** Can't write to `/project/R_libs`

**Solution:**
```bash
# Check ownership on host
ls -ld R_libs
# Should be owned by you

# Fix if needed
chmod 755 R_libs
```

### Container Can't See R_libs

**Symptom:** `list.files("/project/R_libs")` returns empty

**Solution:**
```bash
# Check binding in launch script
grep "bind" run_rstudio.sh
# Should have: --bind "${PROJECT_DIR}:/project"

# Test binding manually
singularity exec --bind "$(pwd):/project" rstudio.sif ls /project/R_libs
```

### Installation Fails with "Non-zero exit status"

**Symptom:** `install_cran()` fails

**Solution:**
```r
# Check repos are set
getOption("repos")
# Should show CRAN URL

# Check network from container
system("curl -I https://cloud.r-project.org")

# Install with verbose output
install.packages("package", lib = "/project/R_libs", verbose = TRUE)
```

##  Best Practices

### 1. Regular Reproducibility Reports

```r
# At project milestones
generate_full_reproducibility()

# Commit to version control:
git add install_local_packages.R
git add r_reproducibility_report_*.json
git commit -m "Update environment snapshot"
```

### 2. Keep Container Lean

Only bake in packages that:
- Are used across many projects
- Are hard to install (system dependencies)
- Are stable (rarely updated)

Keep in `R_libs/` packages that:
- Are project-specific
- Change frequently
- Are experimental

### 3. Document Your Setup

In your README.md:
```markdown
## Environment

### Container
- Base: rocker/tidyverse:latest
- Includes: tidyverse, Seurat, jsonlite, remotes
- Build: `sudo singularity build rstudio.sif rstudio.def`

### Packages
- Container packages: See rstudio.def
- Project packages: See install_local_packages.R
- Install: `singularity exec rstudio.sif Rscript install_local_packages.R`

### Usage
```bash
./run_rstudio.sh
# Open browser to http://localhost:[PORT]
```
```

### 4. Version Control Strategy

**Commit:**
```
.Rprofile
r_tools/
rstudio.def
run_rstudio.sh
install_local_packages.R
```

**Ignore:**
```
.Rhistory
.RData
.r_install_history.json
R_libs/
rstudio.sif
r_reproducibility_report_*.json
```

##  Summary

Your setup now provides:

 **Containerized RStudio** - Consistent environment
 **External packages** - Survive container rebuilds  
 **Automatic tracking** - Know what you installed
 **Reproducibility** - Easy to recreate environment
 **Flexibility** - Packages in container or R_libs
 **Professional** - Industry-standard practices

The container provides the base, `R_libs/` provides flexibility, and tracking provides reproducibility!
