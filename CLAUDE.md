# CLAUDE.md

This is a project template for running R and RStudio inside a Singularity container with reproducible package management via the `trackR` module.

## Project Structure

```
project/
├── .Rprofile                  # Auto-loads trackR, sets library paths, detects container vs native
├── r_tools/
│   └── track.R                # trackR module - package tracking and container generation
├── r-seurat.def               # Singularity container definition file
├── create_container.sh        # Builds .sif container from .def file (uses --fakeroot)
├── run_r.sh                   # Runs R inside the container
├── run_rstudio.sh             # Launches RStudio Server in the container (interactive)
├── run_rstudio_condor.sh      # Launches RStudio Server via HTCondor batch scheduler
├── submit_rstudio             # HTCondor job submission file for run_rstudio_condor.sh
├── R_libs/                    # Project-local R package library (created at runtime)
├── README.md                  # Full trackR documentation
└── CLAUDE.md                  # This file
```

## How the Template Works

The core idea: install R packages using `trackR` wrapper functions instead of `install.packages()` directly. trackR records every installation with timestamps, sources, and versions. It can then generate a complete Singularity definition file from that history, so the container always matches your environment.

### Workflow

1. Build the Singularity container from `r-seurat.def`
2. Run R or RStudio inside the container
3. Install packages through `trackR` (e.g., `trackr$install_cran("dplyr")`)
4. When ready, generate an updated `.def` file with `trackr$generate_singularity_def()`
5. Rebuild the container with the new packages baked in
6. Repeat as the project evolves

## trackR Module (`r_tools/track.R`)

trackR is sourced automatically by `.Rprofile` on R startup. It provides the `trackr` environment with these key functions:

### Setup
- `trackr$setup_project()` -- interactive project initialization (creates dirs, .Rprofile)

### Installing Packages (use these instead of base R install functions)
- `trackr$install_cran("pkg")` or `trackr$install_cran(c("pkg1", "pkg2"))`
- `trackr$install_bioc("pkg")` -- Bioconductor
- `trackr$install_github("user/repo")` or `trackr$install_github("user/repo@branch")`
- `trackr$install_gitlab("user/repo")`
- `trackr$install_bitbucket("user/repo")`

### Viewing History
- `trackr$show_install_history()` -- all installations
- `trackr$show_install_history(recent = 5)` -- last N
- `trackr$show_install_history(method = "github")` -- filter by source

### Package Analysis
- `trackr$analyze_r_packages()` -- returns list with `manually_installed` and `dependencies`
- `trackr$print_package_summary()`

### Reproducibility
- `trackr$generate_install_script()` -- R script to reinstall all tracked packages
- `trackr$generate_install_script(command_type = "reproduce")` -- version-pinned
- `trackr$generate_container_install_script()` -- for use inside container definitions
- `trackr$generate_full_reproducibility()` -- JSON report + install script
- `trackr$generate_script_from_renv_lock()` -- convert renv.lock to trackR install script

### Singularity Container Generation
- `trackr$generate_singularity_def()` -- generate .def file from tracked packages
- `trackr$generate_singularity_def(build_container = TRUE)` -- generate and build in one step
- `trackr$build_singularity_container()` -- build .sif from existing .def
- `trackr$compare_with_singularity()` -- show packages added/removed since last .def generation

### Help
- `trackr$help()` -- list all functions with examples

### Tracking Data Files
- `.r_install_history.json` -- machine-readable install log
- `.r_install_history.txt` -- human-readable install log

## Building the Singularity Container

The definition file `r-seurat.def` builds from `rocker/tidyverse:latest` (R + RStudio + tidyverse pre-installed). It installs system libraries (HDF5, GDAL, GEOS, PROJ, Cairo, etc.) and base R packages (`remotes`, `jsonlite`).

### Build with the helper script

```bash
./create_container.sh r-seurat.def              # produces r-seurat.sif
./create_container.sh r-seurat.def custom.sif   # custom output name
```

`create_container.sh` runs `singularity build --fakeroot`, logs output to `singularity_build.out`, and tests the resulting container (basic exec, R availability, Seurat loading).

### Build manually

```bash
singularity build --fakeroot r-seurat.sif r-seurat.def
```

### Iterative rebuilds

After installing new packages via trackR:

```r
trackr$compare_with_singularity()     # see what changed
trackr$generate_singularity_def()     # regenerate .def (cumulative, all packages)
trackr$build_singularity_container()  # rebuild from R directly
```

Or from the shell: `./create_container.sh Singularity.def`

Each rebuild starts from a clean base image with all tracked packages -- no incremental patching.

## Running R in the Container

```bash
./run_r.sh                    # interactive R session
./run_r.sh --no-save < script.R   # run a script
./run_r.sh -e "print(1+1)"   # one-liner
```

`run_r.sh` calls `singularity exec` with binds:
- Project directory -> `/project`
- `R_libs/` -> `/project/R_libs`

The container expects `r-seurat.sif` in the project root.

## Running RStudio Server

### Interactive (from login node)

```bash
./run_rstudio.sh
```

This script:
1. Picks a random port (8000-9000)
2. SSHs to the Singularity node (`monod10.mbb.ki.se`)
3. Runs `rserver` inside the container with the same bind mounts as `run_r.sh`
4. Prints instructions for the SSH tunnel

To connect:
1. Set up SSH tunnel: `ssh -N -L <PORT>:monod10.mbb.ki.se:<PORT> <user>@monod.mbb.ki.se`
2. Open `http://localhost:<PORT>` in a browser
3. Log in with your system username and password

### Via HTCondor (batch scheduler)

```bash
condor_submit submit_rstudio
```

This submits `run_rstudio_condor.sh` as a Condor job. Connection details (port, tunnel command) are written to `connection_info.txt` in the project directory.

## .Rprofile Behavior

The `.Rprofile` runs on every R startup and:

1. Detects container vs native environment (checks for `/singularity` file or `SINGULARITY_CONTAINER` env var)
2. Sets the library path:
   - Container: `/project/R_libs`
   - Native: `./R_libs`
3. Creates `R_libs/` if missing
4. Prepends project library to `.libPaths()`
5. Sets CRAN mirror to `https://cloud.r-project.org/` and timeout to 600s
6. Sources `r_tools/track.R` (loads `trackr`)
7. Prints a one-line status summary in interactive sessions

## Singularity Definition File (`r-seurat.def`)

- **Base image:** `rocker/tidyverse:latest` (includes R, RStudio Server, tidyverse)
- **%post:** Installs system dev libraries and `remotes` + `jsonlite` R packages. Seurat install line is commented out (install via trackR instead).
- **%files:** Has commented-out lines for copying `track.R` and an install script into the container. Uncomment these to bake project packages into the image.
- **%environment:** Sets `R_LIBS_USER=/project/R_libs` so the container uses the bound project library.
- **%runscript:** `exec "$@"` -- passes through any command.

## Key Design Decisions

- **Packages live in `R_libs/`, not in the container.** The container provides R, RStudio, and system libraries. R packages are installed to `R_libs/` which is bind-mounted at runtime. This allows package changes without rebuilding the container.
- **Container rebuilds are cumulative.** `generate_singularity_def()` always writes all tracked packages, not just new ones. Each rebuild is a clean slate.
- **trackR replaces renv for container workflows.** Instead of lockfiles, trackR generates container definitions directly. It can also import from `renv.lock` files.
- **The Singularity node is hardcoded** to `monod10.mbb.ki.se` in the run scripts. Change `SINGULARITY_NODE` in `run_rstudio.sh` / `run_rstudio_condor.sh` if deploying elsewhere.
- **The container filename is hardcoded** to `r-seurat.sif` in the run scripts. Update the scripts if using a different name.
