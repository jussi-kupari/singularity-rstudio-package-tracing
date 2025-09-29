#!/usr/bin/env Rscript
# R Package Environment Tracker
# Similar to Python install_tracker.py and package_analyzer.py

#' Install and track R packages
#' 
#' @param packages Character vector of package names
#' @param method Installation method ("cran", "bioc", "github")
#' @param ... Additional arguments passed to installation function
#' @export
install_tracked <- function(packages, method = "cran", ...) {
  # Get project directory
  project_dir <- getwd()
  lib_path <- file.path(project_dir, "R_libs")
  
  # Ensure R_libs exists
  if (!dir.exists(lib_path)) {
    dir.create(lib_path, recursive = TRUE)
  }
  
  # Generate the actual R command (without tracking wrapper)
  actual_command <- if (method == "cran") {
    if (length(packages) == 1) {
      sprintf('install.packages("%s")', packages)
    } else {
      sprintf('install.packages(c(%s))', paste0('"', packages, '"', collapse = ", "))
    }
  } else if (method == "bioc") {
    if (length(packages) == 1) {
      sprintf('BiocManager::install("%s")', packages)
    } else {
      sprintf('BiocManager::install(c(%s))', paste0('"', packages, '"', collapse = ", "))
    }
  } else if (method == "github") {
    if (length(packages) == 1) {
      sprintf('remotes::install_github("%s")', packages)
    } else {
      sprintf('remotes::install_github(c(%s))', paste0('"', packages, '"', collapse = ", "))
    }
  } else {
    deparse(match.call())
  }
  
  # Record installation attempt
  install_log <- list(
    timestamp = Sys.time(),
    packages = packages,
    method = method,
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    platform = R.version$platform,
    command = deparse(match.call()),  # Tracking wrapper command
    actual_command = actual_command,   # Actual R command
    success = FALSE,
    output = NULL
  )
  
  # Perform installation
  tryCatch({
    if (method == "cran") {
      install.packages(packages, lib = lib_path, ...)
    } else if (method == "bioc") {
      if (!requireNamespace("BiocManager", quietly = TRUE)) {
        install.packages("BiocManager", lib = lib_path)
      }
      BiocManager::install(packages, lib = lib_path, update = FALSE, ask = FALSE, ...)
    } else if (method == "github") {
      if (!requireNamespace("remotes", quietly = TRUE)) {
        install.packages("remotes", lib = lib_path)
      }
      remotes::install_github(packages, lib = lib_path, ...)
    } else {
      stop("Unknown method. Use 'cran', 'bioc', or 'github'")
    }
    
    install_log$success <- TRUE
    install_log$output <- "Installation completed successfully"
    message(" Installation successful: ", paste(packages, collapse = ", "))
    
  }, error = function(e) {
    install_log$success <- FALSE
    install_log$output <- as.character(e)
    message(" Installation failed: ", e$message)
  })
  
  # Save to log
  save_install_log(install_log, project_dir)
  
  invisible(install_log)
}

#' Save installation log
save_install_log <- function(log_entry, project_dir = getwd()) {
  log_file_json <- file.path(project_dir, ".r_install_history.json")
  log_file_txt <- file.path(project_dir, ".r_install_history.txt")
  
  # Load existing logs
  if (file.exists(log_file_json)) {
    existing_logs <- jsonlite::fromJSON(log_file_json, simplifyVector = FALSE)
  } else {
    existing_logs <- list()
  }
  
  # Append new log
  existing_logs[[length(existing_logs) + 1]] <- log_entry
  
  # Save JSON
  jsonlite::write_json(existing_logs, log_file_json, pretty = TRUE, auto_unbox = TRUE)
  
  # Save text version
  status <- if (log_entry$success) "✓" else "✗"
  txt_entry <- sprintf(
    "[%s] %s %s\n  Packages: %s\n  Method: %s\n  Command: %s\n\n",
    format(log_entry$timestamp, "%Y-%m-%d %H:%M:%S"),
    status,
    log_entry$method,
    paste(log_entry$packages, collapse = ", "),
    log_entry$method,
    log_entry$actual_command
  )
  
  cat(txt_entry, file = log_file_txt, append = TRUE)
  
  message(" Installation logged")
}

#' Show installation history
#' 
#' @param recent Number of recent installations to show (NULL for all)
#' @param method Filter by installation method
#' @export
show_install_history <- function(recent = NULL, method = NULL) {
  project_dir <- getwd()
  log_file <- file.path(project_dir, ".r_install_history.json")
  
  if (!file.exists(log_file)) {
    message("No installation history found")
    return(invisible(NULL))
  }
  
  history <- jsonlite::fromJSON(log_file, simplifyVector = FALSE)
  
  # Filter by method if specified
  if (!is.null(method)) {
    history <- Filter(function(x) x$method == method, history)
  }
  
  # Limit to recent if specified
  if (!is.null(recent) && length(history) > recent) {
    history <- tail(history, recent)
  }
  
  cat("\n R Package Installation History\n")
  cat(strrep("=", 50), "\n\n")
  
  for (entry in history) {
    status <- if (entry$success) "" else ""
    cat(sprintf("%s %s\n", status, format(as.POSIXct(entry$timestamp), "%Y-%m-%d %H:%M:%S")))
    cat(sprintf("   Method: %s\n", entry$method))
    cat(sprintf("   Packages: %s\n", paste(entry$packages, collapse = ", ")))
    if (!is.null(entry$actual_command)) {
      cat(sprintf("   Command: %s\n", entry$actual_command))
    }
    if (!entry$success && !is.null(entry$output)) {
      cat(sprintf("   Error: %s\n", substr(entry$output, 1, 100)))
    }
    cat("\n")
  }
  
  invisible(history)
}

#' Analyze installed R packages
#' 
#' @param lib_path Path to R library directory
#' @param rhistory_path Path to .Rhistory file
#' @export
analyze_r_packages <- function(lib_path = "R_libs", rhistory_path = ".Rhistory") {
  
  # Check if lib_path exists
  if (!dir.exists(lib_path)) {
    message("R library directory not found: ", lib_path)
    return(list(manually_installed = list(), dependencies = list()))
  }
  
  # Read .Rhistory if available
  history_lines <- if (file.exists(rhistory_path))
    readLines(rhistory_path, warn = FALSE)
  else
    character(0)
  
  # Read install history log
  install_log <- list()
  log_file <- ".r_install_history.json"
  if (file.exists(log_file)) {
    install_log <- jsonlite::fromJSON(log_file, simplifyVector = FALSE)
  }
  
  # Define install command patterns
  install_patterns <- c(
    "install\\.packages\\(",
    "install_tracked\\(",
    "BiocManager::install\\(",
    "biocLite\\(",
    "devtools::install_github\\(",
    "remotes::install_github\\(",
    "remotes::install_cran\\(",
    "remotes::install_bioc\\(",
    "remotes::install_gitlab\\(",
    "remotes::install_bitbucket\\("
  )
  combined_pattern <- paste(install_patterns, collapse = "|")
  rhistory_commands <- grep(combined_pattern, history_lines, value = TRUE)
  
  # Get all package directories
  pkg_dirs <- list.dirs(lib_path, full.names = TRUE, recursive = FALSE)
  
  manually_installed <- list()
  dependencies <- list()
  
  for (pkg_dir in pkg_dirs) {
    desc_file <- file.path(pkg_dir, "DESCRIPTION")
    pkg_name <- basename(pkg_dir)
    
    if (file.exists(desc_file)) {
      desc <- read.dcf(desc_file)
      metadata <- as.list(desc[1, ])
      
      # Check install log first
      log_match <- NULL
      for (entry in install_log) {
        if (pkg_name %in% entry$packages) {
          log_match <- entry
          break
        }
      }
      
      # Then check .Rhistory
      rhistory_match <- grep(paste0(pkg_name, "\"?\\)?"), rhistory_commands, value = TRUE)
      
      # Record installation info
      metadata$InstallCommandUsed <- if (!is.null(log_match)) {
        log_match$command
      } else if (length(rhistory_match) > 0) {
        rhistory_match[1]
      } else {
        NA
      }
      
      # Also store the actual R command (not the tracking wrapper)
      metadata$ActualInstallCommand <- if (!is.null(log_match) && !is.null(log_match$actual_command)) {
        log_match$actual_command
      } else if (length(rhistory_match) > 0) {
        rhistory_match[1]  # From .Rhistory, already actual command
      } else {
        NA
      }
      
      metadata$InstallTimestamp <- if (!is.null(log_match)) {
        log_match$timestamp
      } else {
        NA
      }
      
      metadata$InstallMethod <- if (!is.null(log_match)) {
        log_match$method
      } else {
        NA
      }
      
      # Reconstruct install command
      version <- metadata$Version
      repo <- metadata$Repository
      remote_type <- metadata$RemoteType
      remote_repo <- metadata$RemoteRepo
      remote_user <- metadata$RemoteUsername
      remote_ref <- metadata$RemoteRef
      
      if (!is.null(remote_type) && !is.na(remote_type) &&
          remote_type == "github" &&
          !is.null(remote_repo) && !is.na(remote_repo) &&
          !is.null(remote_user) && !is.na(remote_user)) {
        ref <- if (!is.null(remote_ref) && !is.na(remote_ref))
          remote_ref
        else
          "HEAD"
        metadata$ReproduceInstall <- paste0("remotes::install_github(\"",
                                            remote_user,
                                            "/",
                                            remote_repo,
                                            "@",
                                            ref,
                                            "\")")
        
      } else if (!is.null(repo) && !is.na(repo) && grepl("BioC", repo)) {
        metadata$ReproduceInstall <- paste0("BiocManager::install(\"",
                                            pkg_name,
                                            "\") # version: ",
                                            version)
        
      } else if (!is.null(repo) && !is.na(repo) && repo == "CRAN") {
        metadata$ReproduceInstall <- paste0("remotes::install_version(\"",
                                            pkg_name,
                                            "\", version = \"",
                                            version,
                                            "\")")
        
      } else {
        # Fallback: assume CRAN if version is present
        if (!is.null(version) && !is.na(version)) {
          metadata$ReproduceInstall <- paste0("remotes::install_version(\"",
                                              pkg_name,
                                              "\", version = \"",
                                              version,
                                              "\")")
        } else {
          metadata$ReproduceInstall <- paste0("# Unknown source for ", pkg_name)
        }
      }
      
      # Classify
      if (!is.na(metadata$InstallCommandUsed)) {
        manually_installed[[pkg_name]] <- metadata
      } else {
        dependencies[[pkg_name]] <- metadata
      }
    }
  }
  
  list(manually_installed = manually_installed, 
       dependencies = dependencies,
       summary = list(
         total_packages = length(c(manually_installed, dependencies)),
         manually_installed_count = length(manually_installed),
         dependencies_count = length(dependencies),
         r_version = paste(R.version$major, R.version$minor, sep = "."),
         lib_path = lib_path
       ))
}

#' Print package analysis summary
#' 
#' @param analysis Result from analyze_r_packages()
#' @export
print_package_summary <- function(analysis = analyze_r_packages()) {
  cat("\n R Package Analysis Summary\n")
  cat(strrep("=", 50), "\n")
  cat(sprintf("R version: %s\n", analysis$summary$r_version))
  cat(sprintf("Library path: %s\n", analysis$summary$lib_path))
  cat(sprintf("Total packages: %d\n", analysis$summary$total_packages))
  cat(sprintf("Manually installed: %d\n", analysis$summary$manually_installed_count))
  cat(sprintf("Dependencies: %d\n", analysis$summary$dependencies_count))
  
  if (analysis$summary$dependencies_count > 0) {
    cat("\nPackages without install history:\n")
    for (pkg_name in names(analysis$dependencies)) {
      pkg <- analysis$dependencies[[pkg_name]]
      cat(sprintf("  - %s (%s)\n", pkg_name, pkg$Version))
    }
  }
  
  invisible(analysis)
}

#' Generate reproducibility report
#' 
#' @param output_file Output JSON file path
#' @export
generate_reproducibility_report <- function(output_file = NULL) {
  analysis <- analyze_r_packages()
  
  report <- list(
    generated_at = Sys.time(),
    r_version = paste(R.version$major, R.version$minor, sep = "."),
    platform = R.version$platform,
    lib_path = analysis$summary$lib_path,
    total_packages = analysis$summary$total_packages,
    manually_installed = analysis$manually_installed,
    dependencies = analysis$dependencies
  )
  
  # Generate default filename if not provided
  if (is.null(output_file)) {
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    output_file <- paste0("r_reproducibility_report_", timestamp, ".json")
  }
  
  jsonlite::write_json(report, output_file, pretty = TRUE, auto_unbox = TRUE)
  
  message(" Reproducibility report saved: ", output_file)
  message("   Total packages: ", report$total_packages)
  message("   Manually installed: ", length(analysis$manually_installed))
  message("   Dependencies: ", length(analysis$dependencies))
  
  invisible(report)
}

#' Generate install script
#' 
#' @param package_info Result from analyze_r_packages()
#' @param use_reproduce Use ReproduceInstall commands instead of original
#' @param include_dependencies Include dependency packages
#' @param output_file Output file path
#' @export
generate_install_script <- function(package_info = NULL,
                                    use_reproduce = TRUE,
                                    include_dependencies = FALSE,
                                    output_file = "install_r_packages.R") {
  
  if (is.null(package_info)) {
    package_info <- analyze_r_packages()
  }
  
  get_command <- function(pkg_data) {
    # Priority:
    # 1. ActualInstallCommand (from log, without tracking wrapper)
    # 2. ReproduceInstall (version-pinned command)
    # 3. InstallCommandUsed (from .Rhistory)
    
    if (use_reproduce && !is.null(pkg_data$ReproduceInstall)) {
      return(pkg_data$ReproduceInstall)
    } else if (!is.null(pkg_data$ActualInstallCommand) && !is.na(pkg_data$ActualInstallCommand)) {
      return(pkg_data$ActualInstallCommand)
    } else if (!is.null(pkg_data$InstallCommandUsed) && !is.na(pkg_data$InstallCommandUsed)) {
      return(pkg_data$InstallCommandUsed)
    } else {
      return(NULL)
    }
  }
  
  manual_cmds <- lapply(package_info$manually_installed, get_command)
  manual_cmds <- Filter(Negate(is.null), manual_cmds)
  
  dep_cmds <- character(0)
  if (include_dependencies) {
    dep_cmds <- lapply(package_info$dependencies, function(pkg_data) {
      if (!is.null(pkg_data$ReproduceInstall)) {
        return(pkg_data$ReproduceInstall)
      } else {
        return(NULL)
      }
    })
    dep_cmds <- Filter(Negate(is.null), dep_cmds)
  }
  
  all_cmds <- unique(c(manual_cmds, dep_cmds))
  
  # Create script with header
  script_lines <- c(
    "#!/usr/bin/env Rscript",
    "# R Package Installation Script",
    paste("#", "Generated:", Sys.time()),
    paste("#", "R version:", paste(R.version$major, R.version$minor, sep = ".")),
    "",
    "# Set library path",
    "lib_path <- 'R_libs'",
    "if (!dir.exists(lib_path)) dir.create(lib_path, recursive = TRUE)",
    ".libPaths(c(lib_path, .libPaths()))",
    "",
    "# Install packages",
    unlist(all_cmds)
  )
  
  script <- paste(script_lines, collapse = "\n")
  
  if (!is.null(output_file)) {
    writeLines(script_lines, output_file)
    Sys.chmod(output_file, mode = "0755")
    message(" Install script saved: ", output_file)
  }
  
  invisible(script)
}

#' Check R versions in library
#' 
#' @param lib_base Base library path (default: current directory)
#' @export
check_r_versions <- function(lib_base = ".") {
  cat("\n Checking for R library installations\n")
  cat(strrep("=", 50), "\n\n")
  
  # Check for R_libs directories
  r_lib_patterns <- c("R_libs", "renv", ".Rlibs")
  
  found_libs <- character(0)
  for (pattern in r_lib_patterns) {
    lib_path <- file.path(lib_base, pattern)
    if (dir.exists(lib_path)) {
      found_libs <- c(found_libs, lib_path)
    }
  }
  
  if (length(found_libs) == 0) {
    cat(" No R library directories found\n")
    cat("   Expected directories: R_libs/\n")
    return(invisible(NULL))
  }
  
  for (lib_path in found_libs) {
    pkg_dirs <- list.dirs(lib_path, full.names = FALSE, recursive = FALSE)
    pkg_count <- length(pkg_dirs)
    
    cat(sprintf(" %s: %d packages\n", basename(lib_path), pkg_count))
    cat(sprintf("   Path: %s\n", lib_path))
  }
  
  cat(sprintf("\nCurrent R: %s.%s\n", R.version$major, R.version$minor))
  cat(sprintf("Will analyze: %s\n", found_libs[1]))
  
  invisible(found_libs)
}

#' Complete reproducibility workflow
#' 
#' @export
generate_full_reproducibility <- function() {
  cat(" Generating complete R reproducibility package...\n\n")
  
  cat("1. Analyzing packages...\n")
  analysis <- analyze_r_packages()
  
  cat("2. Generating reproducibility report...\n")
  report_file <- generate_reproducibility_report()
  
  cat("3. Generating install script...\n")
  script_file <- generate_install_script(analysis)
  
  cat("4. Package summary:\n")
  print_package_summary(analysis)
  
  cat("\n Reproducibility package complete!\n")
  cat("Files created:\n")
  cat(sprintf("  - %s\n", report_file))
  cat(sprintf("  - %s\n", script_file))
  cat("\nTo reproduce this environment:\n")
  cat(sprintf("  Rscript %s\n", script_file))
  
  invisible(list(analysis = analysis, report_file = report_file, script_file = script_file))
}

# Convenience wrapper functions
install_cran <- function(...) install_tracked(..., method = "cran")
install_bioc <- function(...) install_tracked(..., method = "bioc")
install_github <- function(...) install_tracked(..., method = "github")

#' Generate container-ready install script
#' 
#' Creates an R script suitable for use in Singularity container %post section
#' Uses actual R commands (not tracking wrappers)
#' 
#' @param package_info Result from analyze_r_packages()
#' @param include_dependencies Include auto-installed dependencies
#' @param output_file Output file path
#' @param format Output format: "r_script" or "singularity_post"
#' @export
generate_container_install_script <- function(package_info = NULL,
                                               include_dependencies = FALSE,
                                               output_file = "install_for_container.R",
                                               format = c("r_script", "singularity_post")) {
  
  format <- match.arg(format)
  
  if (is.null(package_info)) {
    package_info <- analyze_r_packages()
  }
  
  # Get actual R commands (not tracking wrappers)
  get_actual_command <- function(pkg_data) {
    # Use ActualInstallCommand if available (from tracking)
    if (!is.null(pkg_data$ActualInstallCommand) && !is.na(pkg_data$ActualInstallCommand)) {
      return(pkg_data$ActualInstallCommand)
    }
    # Otherwise use ReproduceInstall (version-pinned)
    if (!is.null(pkg_data$ReproduceInstall)) {
      return(pkg_data$ReproduceInstall)
    }
    return(NULL)
  }
  
  # Get commands for manually installed packages
  manual_cmds <- lapply(package_info$manually_installed, get_actual_command)
  manual_cmds <- Filter(Negate(is.null), manual_cmds)
  
  # Get commands for dependencies if requested
  dep_cmds <- character(0)
  if (include_dependencies) {
    dep_cmds <- lapply(package_info$dependencies, function(pkg_data) {
      if (!is.null(pkg_data$ReproduceInstall)) {
        return(pkg_data$ReproduceInstall)
      }
      return(NULL)
    })
    dep_cmds <- Filter(Negate(is.null), dep_cmds)
  }
  
  all_cmds <- unique(c(manual_cmds, dep_cmds))
  
  if (format == "r_script") {
    # Regular R script format
    script_lines <- c(
      "#!/usr/bin/env Rscript",
      "# R Package Installation Script for Container",
      paste("#", "Generated:", Sys.time()),
      paste("#", "R version:", paste(R.version$major, R.version$minor, sep = ".")),
      "",
      "# Note: This script uses actual R commands, not tracking wrappers",
      "# Suitable for use in Singularity container %post section",
      "",
      "cat('Installing packages...\\n')",
      "",
      unlist(all_cmds),
      "",
      "cat('Installation complete!\\n')"
    )
  } else {
    # Singularity %post format
    script_lines <- c(
      "# Add these lines to your Singularity definition %post section",
      paste("#", "Generated:", Sys.time()),
      paste("#", "Based on R version:", paste(R.version$major, R.version$minor, sep = ".")),
      "",
      "# Package installations",
      sapply(all_cmds, function(cmd) {
        paste0('    R -e "', cmd, '"')
      })
    )
  }
  
  script <- paste(script_lines, collapse = "\n")
  
  if (!is.null(output_file)) {
    writeLines(script_lines, output_file)
    if (format == "r_script") {
      Sys.chmod(output_file, mode = "0755")
    }
    message(" Container install script saved: ", output_file)
    message("   Format: ", format)
    message("   Commands: ", length(all_cmds))
  }
  
  invisible(script)
}
