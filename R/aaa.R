#' @include utils.R
NULL

#' Available linters
#' @name linters
#'
#' @description A variety of linters are available in \pkg{lintr}. The most popular ones are readily
#' accessible through [default_linters()].
#'
#' Within a [lint()] function call, the linters in use are initialized with the provided
#' arguments and fed with the source file (provided by [get_source_expressions()]).
#'
#' A data frame of all available linters can be retrieved using [available_linters()].
#' Documentation for linters is structured into tags to allow for easier discovery;
#' see also [available_tags()].
#'
#' @evalRd rd_taglist()
#' @evalRd rd_linterlist()
NULL

# need to register rex shortcuts as globals to avoid CRAN check errors
rex::register_shortcuts("lintr")

utils::globalVariables(
  c(
    "line1", "col1", "line2", "col2", # columns of parsed_content
    "id", "parent", "token", "terminal", "text" # ditto
  ),
  "lintr"
)
