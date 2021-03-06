#' Generator for function with multiple peaks following the multiple peaks model 2.
#'
#' @param n.peaks [\code{integer(1)}]\cr
#'   Desired number of peaks, i. e., number of (local) optima.
#' @template arg_dimensions
#' @param topology [\code{integer(1)}]\cr
#'   Type of topology. Possible values are \dQuote{random} and \dQuote{funnel}.
#' @param seed [\code{integer(1)}]\cr
#'   Seed for the random numbers generator.
#' @return [\code{smoof_single_objective_function}]
#' @examples
#' \dontrun{
#' fn = makeMPM2Function(n.peaks = 10L, dimensions = 2L, topology = "funnel", seed = 123)
#' if (require(plot3D)) {
#'   plot3D(fn)
#' }
#' }
#' \dontrun{
#' fn = makeMPM2Function(n.peaks = 5L, dimensions = 2L, topology = "random", seed = 134)
#' plot(fn, render.levels = TRUE)
#' }
#'
#' @references See the \href{https://ls11-www.cs.uni-dortmund.de/_media/techreports/tr15-01.pdf}{technical report}
#' of multiple peaks model 2 for an in-depth description of the underlying algorithm.
#'
#' @author \R interface by Jakob Bossek. Original python code
#' provided by the Simon Wessing.
#'
#' @export
makeMPM2Function = function(n.peaks, dimensions, topology, seed) {
  if (isWindows()) {
    stopf("No support for the multiple peaks model 2 generator at the moment.")
  }

  # do some sanity checks
  n.peaks = convertInteger(n.peaks)
  dimensions = convertInteger(dimensions)
  seed = convertInteger(seed)
  assertInt(n.peaks, lower = 1L, na.ok = FALSE)
  assertInt(dimensions, lower = 1L, na.ok = FALSE)
  assertChoice(topology, choices = c("random", "funnel"))
  assertInt(seed, lower = 1L, na.ok = FALSE)

  # touch vars
  force(n.peaks)
  force(dimensions)
  force(topology)
  force(seed)

  # build parameter set (bounds are [0, 1]^d)
  par.set = makeNumericParamSet("x", len = dimensions, lower = 0, upper = 1)

  # import rPython namespace
  BBmisc::requirePackages("_rPython", why = "smoof::makeMultiplePeaksModel2Function")

  # load funnel generator to global environemt
  eval(rPython::python.load(system.file("mpm2.py", package = "smoof")), envir = .GlobalEnv)

  makeSingleObjectiveFunction(
    name = sprintf("Funnel_%i_%i_%i_%s", n.peaks, dimensions, seed, topology),
    description = sprintf("Funnel-like function\n(n.peaks: %i, dimension: %i, topology: %s, seed: %i)",
      n.peaks, dimensions, topology, seed),
    fn = function(x) {
      assertNumeric(x, len = dimensions, any.missing = FALSE, all.missing = FALSE)
      rPython::python.call("evaluateProblem", as.numeric(x), n.peaks, dimensions, topology, seed)
    },
    par.set = par.set,
    tags = c("non-separable", "scalable", "continuous", "multimodal")
  )
}

class(makeMPM2Function) = c("function", "smoof_generator")
attr(makeMPM2Function, "name") = c("Multiple peals model 2 function generator")
attr(makeMPM2Function, "type") = c("single-objective")
