# Unified Environment Tools: Python & R

A consistent approach to package management and reproducibility across both Python and R projects.

##  Philosophy

Both tool sets follow the same design principles:
1. **Track installations automatically** during development
2. **Analyze actual packages** in addition to history
3. **Generate reproducibility files** on demand
4. **Integrate seamlessly** into workflow via startup files
5. **Provide both CLI and interactive** interfaces

##  Unified Project Structure

```
your-project/
├── Python Environment
│   ├── .pythonrc                        # Python startup
│   ├── .python_history                  # Python command history
│   ├── .python_install_history.json     # Python install log
│   ├── requirements.txt                 # Python requirements
│   ├── python_libs/                     # Python packages
│   │   └── lib/python3.X/site-packages/
│   └── python_tools/                    # Python tools
│       ├── install_tracker.py
│       ├── package_analyzer.py
│       ├── install_history_cli.py
│       ├── package_analyzer_cli.py
│       └── README.md
│
├── R Environment
│   ├── .Rprofile                        # R startup
│   ├── .Rhistory                        # R command history
│   ├── .r_install_history.json          # R install log
│   ├── install_r_packages.R             # R install script
│   ├── R_libs/                          # R packages
│   │   └── [packages]/
│   └── r_tools/                         # R tools
│       ├── package_tracker.R
│       └── README.md
│
├── Containers
│   ├── python.sif / scanpy.sif          # Python container
│   ├── rstudio.sif                      # R/RStudio container
│   ├── run_python.sh                    # Python launcher
│   └── run_rstudio.sh                   # RStudio launcher
│
└── Your Work
    ├── data/
    ├── scripts/
    ├── notebooks/
    └── results/
```

##  Parallel Workflows

### Python Workflow

```python
# Start Python
./run_python.sh

# Install packages (tracked)
install('numpy', 'pandas', 'scipy')
install_bioc('scanpy')
git_install('user/repo')

# Check status
quick_summary()
show_installs()

# Generate reproducibility
generate_reproducibility()
```

**Files Created:**
- `.python_install_history.json` - Installation log
- `requirements.txt` - Package requirements
- `reproducibility_report_*.json` - Full report

### R Workflow

```r
# Start R
# (or launch RStudio)

# Install packages (tracked)
install_cran("dplyr", "ggplot2", "tidyr")
install_bioc("DESeq2", "limma")
install_github("user/repo")

# Check status
print_package_summary()
show_install_history()

# Generate reproducibility
generate_full_reproducibility()
```

**Files Created:**
- `.r_install_history.json` - Installation log
- `install_r_packages.R` - Install script
- `r_reproducibility_report_*.json` - Full report

##  Feature Comparison

| Feature | Python | R |
|---------|--------|---|
| **Auto-tracking** |  `install()` |  `install_cran()` |
| **History logging** |  JSON + text |  JSON + text |
| **Package analysis** |  Scans site-packages |  Scans R_libs |
| **Version detection** |  Auto-detects Python version |  Uses current R version |
| **CLI tools** |  Shell scripts |  (R-only) |
| **Startup integration** |  `.pythonrc` |  `.Rprofile` |
| **Reproducibility reports** |  JSON format |  JSON format |
| **Install scripts** |  requirements.txt |  install_r_packages.R |
| **Dependency tracking** |  Auto-installed deps |  Auto-installed deps |
| **Multiple sources** |  pip/conda/git |  CRAN/Bioc/GitHub |

##  Quick Start Guide

### Setup Both Environments

```bash
# 1. Create directory structure
mkdir -p python_tools r_tools

# 2. Add tool files
# - Add Python files to python_tools/
# - Add R files to r_tools/

# 3. Create startup files
# - Create .pythonrc in project root
# - Create .Rprofile in project root

# 4. Make Python scripts executable
chmod +x python_tools/*.sh

# 5. Test setup
./run_python.sh  # Should load Python tools
# Start R/RStudio  # Should load R tools
```

### Daily Usage

**Python Session:**
```bash
./run_python.sh
```
```python
install('seaborn')
quick_summary()
```

**R Session:**
```bash
# Launch RStudio or start R
```
```r
install_cran("ggplot2")
print_package_summary()
```

### Generate Reproducibility Package

**For Python:**
```bash
./python_tools/package_analyzer.sh reproduce
```
Or in Python:
```python
generate_reproducibility()
```

**For R:**
```r
generate_full_reproducibility()
```

### Reproduce Environments

**Python:**
```bash
pip install -r requirements.txt
# Or use the container
```

**R:**
```bash
Rscript install_r_packages.R
# Or source in R session
```

##  Working with Mixed Projects

If your project uses both Python and R:

### Organize by Language

```
your-mixed-project/
├── python/                    # Python-specific work
│   ├── scripts/
│   └── notebooks/
├── r/                        # R-specific work
│   ├── scripts/
│   └── notebooks/
├── python_tools/             # Python environment tools
├── r_tools/                  # R environment tools
├── python_libs/              # Python packages
├── R_libs/                   # R packages
└── shared/                   # Language-agnostic
    ├── data/
    └── results/
```

### Document Both Environments

In your README:

```markdown
## Environment Setup

### Python Environment
```bash
pip install -r requirements.txt
```

### R Environment
```bash
Rscript install_r_packages.R
```

### Verify Setup
- Python: `./python_tools/package_analyzer.sh summary`
- R: `print_package_summary()` in R console
```

### Generate Combined Report

```bash
# Python reproducibility
./python_tools/package_analyzer.sh reproduce

# R reproducibility
Rscript -e "source('r_tools/package_tracker.R'); generate_full_reproducibility()"

# Now you have:
# - requirements.txt (Python)
# - install_r_packages.R (R)
# - reproducibility_report_*.json (Python)
# - r_reproducibility_report_*.json (R)
```

##  Best Practices Across Both

### 1. Consistent Tracking
- **Python:** Always use `install()`, not `!pip install`
- **R:** Always use `install_cran()`, not `install.packages()`

### 2. Regular Reports
```bash
# Weekly or at milestones
./python_tools/package_analyzer.sh summary
```
```r
print_package_summary()
```

### 3. Before Commits
```bash
# Generate reproducibility files
./python_tools/package_analyzer.sh reproduce
```
```r
generate_full_reproducibility()
```

### 4. Version Control

**Commit:**
- Tool files (`python_tools/`, `r_tools/`)
- Startup files (`.pythonrc`, `.Rprofile`)
- Final reproducibility files
- Launch scripts

**Ignore:**
- Package directories (`python_libs/`, `R_libs/`)
- History files (`.python_history`, `.Rhistory`)
- Temporary logs
- Container images (`.sif` files - too large)

### 5. Documentation

In your project documentation:

```markdown
## Environment Management

### Python
- Packages in `python_libs/`
- Track installs: `install('package')`
- Check status: `quick_summary()`
- Generate report: `generate_reproducibility()`

### R
- Packages in `R_libs/`
- Track installs: `install_cran('package')`
- Check status: `print_package_summary()`
- Generate report: `generate_full_reproducibility()`

### Reproducibility Files
- Python: `requirements.txt`
- R: `install_r_packages.R`
- Reports: `*reproducibility_report*.json`
```

##  Troubleshooting Common Issues

### Tools Not Loading

**Python:**
```bash
# Check .pythonrc exists
ls -la .pythonrc

# Check PYTHONSTARTUP is set in run_python.sh
grep PYTHONSTARTUP run_python.sh
```

**R:**
```r
# Check .Rprofile exists
file.exists(".Rprofile")

# Manually source if needed
source(".Rprofile")
```

### Packages Installing to Wrong Location

**Python:**
```python
import sys
sys.path  # Check if /project/python_libs/... is first
```

**R:**
```r
.libPaths()  # Check if R_libs is first
```

### History Not Tracking

**Python:**
- Verify you're using `install()` not `pip install`
- Check `.python_install_history.json` is writable

**R:**
- Verify you're using `install_cran()` not `install.packages()`
- Check `.r_install_history.json` is writable

### Version Mismatches

**Python:**
```bash
# Check Python version
python --version

# Check detected version
./python_tools/package_analyzer.sh versions
```

**R:**
```r
# Check R version
R.version

# Check library compatibility
check_r_versions()
```

##  Additional Resources

### Python Tools Documentation
- Full guide: `python_tools/README.md`
- Project structure: See project root documentation
- CLI reference: `./python_tools/*.sh --help`

### R Tools Documentation
- Full guide: `r_tools/README.md`
- Function reference: `?install_cran`, etc.
- Example workflows: See R tools guide

### Container Integration
Both tool sets work seamlessly with Singularity containers:
- Python: Automatically uses container Python version
- R: Automatically uses container R version
- Both: Package directories bound to containers

##  Benefits of This Unified Approach

1. **Consistency** - Same workflow for both languages
2. **Reproducibility** - Complete environment documentation
3. **Flexibility** - Works with or without containers
4. **Maintainability** - Easy to update and extend
5. **Shareability** - Self-contained tool directories
6. **Professional** - Industry-standard practices
7. **Documented** - Comprehensive guides for both

You now have a complete, professional-grade environment management system for both Python and R!
