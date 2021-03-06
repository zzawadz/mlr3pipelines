# simple feature transform, no hyperpars
PipeOpNULL = R6Class("PipeOpNULL",

  inherit = PipeOp,

  public = list(
    initialize = function(id = "OpNULL") {
      super$initialize(id)
    },

    train2 = function() {
      assert_list(self$inputs, len = 1L, type = "Task")
      self$inputs[[1L]]
    },

    predict2 = function(inputs) {
      return(inputs)
    }
  )
)

# simple feature transform, no hyperpars
PipeOpPCA = R6Class("PipeOpPCA",

  inherit = PipeOp,

  public = list(
    initialize = function(id = "pca") {
      super$initialize(id)
    },

    train2 = function() {
      assert_list(self$inputs, len = 1L, type = "Task")
      # FIXME: this is really bad code how i change the data of the task
      # ich muss hier das backend austauschen
      task = self$inputs[[1L]]
      fn = task$feature_names
      d = task$data()
      pcr = prcomp(as.matrix(d[, ..fn]), center = FALSE, scale. = FALSE)
      private$.params = pcr$rotation
      d[, fn] = as.data.table(pcr$x)
      
      db <- DataBackendDataTable$new(d)
      TaskClassif$new(id = task$id, backend = db, target = task$target_names)
    },

    predict2 = function() {
      assert_list(self$inputs, len = 1L, type = "Task")
      # FIXME: Make sure dimensions fit (if input did not have full rank)
      as.data.frame(as.matrix(input) %*% self$params)
    }
  )
)

# simple feature transform, but hyperpars
PipeOpScaler = R6Class("PipeOpScaler",

  inherit = PipeOp,

  public = list(
    initialize = function(id = "scaler") {

      ps = ParamSet$new(params = list(
        ParamFlag$new("center", default = TRUE),
        ParamFlag$new("scale", default = TRUE)
      ))
      super$initialize(id, ps)
    },

    train2 = function() {
      assert_list(self$inputs, len = 1L, type = "Task")
      task = self$inputs[[1L]]
      # FIXME: this is really bad code how i change the data of the task
      fn = task$feature_names
      d = task$data()
      sc = scale(as.matrix(d[, ..fn]),
        center = self$par_vals$center, scale = self$par_vals$scale)

      private$.params = list(
        center = attr(sc, "scaled:center") %??% FALSE,
        scale = attr(sc, "scaled:scale") %??% FALSE
      )
      d[, fn] = as.data.table(sc)
      
      db <- DataBackendDataTable$new(d)
      TaskClassif$new(id = task$id, backend = db, target = task$target_names)
    },

    predict2 = function() {
      assert_list(self$inputs, len = 1L, type = "Task")
      task = self$inputs[[1L]]
      as.data.frame(scale(as.matrix(input),
        center = self$params$center, scale = self$params$scale))
    }
  )
)

# simple feature transform, no hyperpars
PipeOpDownsample = R6Class("PipeOpDownsample",

  inherit = PipeOp,

  public = list(
    initialize = function(id = "downsample") {
      ps = ParamSet$new(params = list(
        ParamNum$new("perc", default = 0.7, lower = 0, upper = 1),
        ParamLogical$new("stratify", default = FALSE)
      ))
      super$initialize(id, ps)
    },

    train2 = function() {
      assert_list(self$inputs, len = 1L, type = "Task")
      # FIXME: this is really bad code how i change the data of the task
      # ich muss hier das backend austauschen
      task = self$inputs[[1L]]
      fn = task$feature_names
      # FIXME: Discuss whether we want to use the current mlr implementation
      TaskClassif$new(id = task$id, data = d, target = task$target_names)
    },

    predict2 = function() {
      assert_list(self$inputs, len = 1L, type = "Task")
      # FIXME: Make sure dimensions fit (if input did not have full rank)
      as.data.frame(as.matrix(input) %*% self$params)
    }
  )
)

# cpoNull = PipeOp$new(
#   id = "null",
#   in.format = "task",
#   out.format = "task",
#   train = function(inlist, par_vals) {
#     list(
#       control = list(),
#       task = task
#     )
#   },

#   predict = function(inlist, control) {
#     list(
#       task = inlist$task
#     )
#   },

#   par_set = ParamSet$new()
# )

# cpoDropConst = PipeOp$new(
#   id = "dropconst",
#   in.format = "data-target",
#   out.format = "data",

#   train = function(inlist, par_vals) {

#   # perc = 0, na.ignore = FALSE, tol = .Machine$double.eps^.5

#     #FIXME: where to put these asserts?
#     # can phng handle this now automatically?

#     # assertNumber(perc, lower = 0, upper = 1)
#     # assertSubset(dont.rm, choices = names(data))
#     # assertFlag(na.ignore)
#     # assertNumber(tol, lower = 0)

#     isEqual = function(x, y) {
#       res = (x == y) | (is.na(x) & is.na(y))
#       replace(res, is.na(res), FALSE)
#     }
#     #FIXME: this function was really slow due to computeMode in BBmisc. what to do?
#     # sorting the vector first is probably a good idea. then iterate in C
#     digits = ceiling(log10(1 / tol))
#     cns = setdiff(colnames(data), dont.rm)
#     ratio = vnapply(data[cns], function(x) {
#       if (allMissing(x))
#         return(0)
#       if (is.double(x))
#         x = round(x, digits = digits)
#       m = computeMode(x, na.rm = par_vals$na.ignore, ties.method = "first")
#       if (par_vals$na.ignore) {
#         mean(m != x, na.rm = TRUE)
#       } else {
#         mean(!isEqual(x, m))
#       }
#     }, use.names = FALSE)

#     dropped.cols = cns[ratio <= perc]
#     # FIXME: do we show such messages in verbose mode?
#     # if (show.info && length(dropcols))
#       # messagef("Removing %i columns: %s", length(dropcols), collapse(dropcols))
#     dropNamed(data, dropcols)
#     list(
#       data = dropNamed(data, drop.cols),
#       drop.cols = drop.cols
#     )
#   },

#   predict = function(inlist, control) {
#     data[control$dropped.cols]
#   },

#   par_set = ParamSet$new(params = list(
#     ParamReal$new("perc", default = 0.005, lower = 0, upper = 1),
#     ParamReal$new("tol", default = .Machine$double.eps^.5, lower = 0, upper = 1),
#     ParamFlag$new("na.ignore", default = FALSE)
#   ))
# )


