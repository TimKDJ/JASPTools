#' Tell jaspTools what module you are currently working on.
#'
#' These module are used to find the R functions etc. in \code{runAnalysis} and the various testing functions.
#'
#' @param modulePaths Path to the root of the module (if no path is specified, then the current working directory will be used).
#' @param installDeps Should jaspTools install missing dependencies of the specified module(s)?
#' @examples
#'
#' setActiveModule(c("~/Documents/Github/Regression", "~/Document/Github/Frequencies"))
#'
#' @export setActiveModule
setActiveModule <- function(modulePaths = ".", installDeps = TRUE) {
  validModulePaths <- verifyModulePaths(modulePaths)
  if (length(validModulePaths) == 0)
    stop("No valid module(s) supplied in `modulePaths`. Note that all JASP modules should be valid R packages and have these files: DESCRIPTION, NAMESPACE and inst/Description.qml.")

  .setInternal("modulePaths", validModulePaths)
  message("Monitoring: ", paste(validModulePaths, collapse = ", "))

  if (installDeps) {
    message("Installing missing dependencies")
    for (modulePath in validModulePaths)
      remotes::install_deps(modulePath, upgrade = "never", INSTALL_opts = "--no-multiarch")
  }
}

findCorrectFunction <- function(funName) {
  modulePath <- getModulePathFromRFunction(funName)
  if (is.null(modulePath))
    stop("Could not locate the module location for `", funName, "`")

  return(paste(getModuleName(modulePath), funName, sep = "::"))
}

getModulePaths <- function() {
  modulePaths <- .getInternal("modulePaths")
  if (modulePaths == "") {
    if (setWorkDirAsModule())
      modulePaths <- .getInternal("modulePaths")
    else
      stop("jaspTools needs to know what module to obtain resources from. Please set the current working directory to your JASP module, or specify it through `setActiveModule(\"path/to/module\")`")
  }

  return(modulePaths)
}

setWorkDirAsModule <- function() {
  if (!is.null(verifyModulePaths(getwd()))) {
    message("Current working directory is a JASP module, using that (to override this behaviour use `setActiveModule()`)")
    setActiveModule(getwd())
    return(TRUE)
  }
  return(FALSE)
}

verifyModulePaths <- function(modulePaths) {
  validModulePaths <- NULL
  if (length(modulePaths) > 0 && any(modulePaths != "")) {
    for (modulePath in modulePaths) {
      validModuleRoot <- getValidModuleRoot(modulePath)
      if (!is.null(validModuleRoot))
        validModulePaths <- c(validModulePaths, validModuleRoot)
    }
  }

  return(validModulePaths)
}

getModulePathFromRFunction <- function(funName) {
  modulePath <- NULL

  modulePaths <- getModulePaths()
  for (i in seq_along(modulePaths))
    if (rFunctionExistsInModule(funName, modulePaths[[i]]))
      modulePath <- modulePaths[i]

  if (is.null(modulePath))
    stop("Could not locate R function `", funName, "` in any of your specified modules. Did you type the R function correctly (it's case sensitive)?")

  return(modulePath)
}

rFunctionExistsInModule <- function(funName, modulePath) {
  env <- new.env()
  rFiles <- list.files(file.path(modulePath, "R"), pattern = "\\.[RrSsQq]$", recursive = TRUE, full.names = TRUE)
  if (length(rFiles) == 0)
    return(FALSE)

  for (rFile in rFiles)
    source(rFile, local = env)

  if (funName %in% names(env))
    return(TRUE)

  return(FALSE)
}

getModulePathsForTesting <- function() {
  modulesWithTests <- NULL
  modulePaths <- getModulePaths()
  for (modulePath in modulePaths) {
    testDir <- file.path(modulePath, "tests", "testthat")
    if (dir.exists(testDir) && length(list.files(testDir)) > 0)
      modulesWithTests <- c(modulesWithTests, modulePath)
  }

  if (length(modulesWithTests) == 0)
    message("No tests were found. Note that the tests should be in `moduleDir/tests/testthat` and named `test-analysisName.R`.")

  return(modulesWithTests)
}

getModuleName <- function(moduleRoot) {
  descrFile <- file.path(moduleRoot, "DESCRIPTION")
  pkgName <- as.vector(read.dcf(descrFile, fields = "Package"))
  if (is.na(pkgName))
    stop("Could not obtain package name from `Package` field in ", descrFile)

  return(pkgName)
}

getValidModuleRoot <- function(path) {
  while (!hasJaspModuleRequisites(path)) {
    parentDir <- dirname(path)
    if (identical(parentDir, dirname(parentDir))) # we're at the root of the filesystem
      return(NULL)
    path <- parentDir
  }
  return(path)
}

moduleRequisites <- function(sep = .Platform$file.sep) {
  return(c("NAMESPACE", "DESCRIPTION", paste("inst", "Description.qml", sep = sep)))
}

hasJaspModuleRequisites <- function(path) {
  all(file.exists(file.path(path, moduleRequisites())))
}
