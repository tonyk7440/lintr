#' Block usage of `file.path()` with `system.file()`
#'
#' [system.file()] has a `...` argument which, internally, is passed to
#'   [file.path()], so including it in user code is repetitive.
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = 'system.file(file.path("path", "to", "data"), package = "foo")',
#'   linters = system_file_linter()
#' )
#'
#' lint(
#'   text = 'file.path(system.file(package = "foo"), "path", "to", "data")',
#'   linters = system_file_linter()
#' )
#'
#' # okay
#' lint(
#'   text = 'system.file("path", "to", "data", package = "foo")',
#'   linters = system_file_linter()
#' )
#'
#' @evalRd rd_tags("system_file_linter")
#' @seealso [linters] for a complete list of linters available in lintr.
#' @export
system_file_linter <- function() {
  funs <- c("system.file", "file.path")
  # either system.file(file.path(...)) or file.path(system.file(...))
  xpath_parts <- glue::glue("
  //SYMBOL_FUNCTION_CALL[text() = '{funs}']
    /parent::expr[following-sibling::expr/expr/SYMBOL_FUNCTION_CALL[text() = '{rev(funs)}']]
    /parent::expr
  ")
  xpath <- paste(xpath_parts, collapse = " | ")

  Linter(function(source_expression) {
    if (!is_lint_level(source_expression, "expression")) {
      return(list())
    }

    xml <- source_expression$xml_parsed_content

    bad_expr <- xml2::xml_find_all(xml, xpath)

    outer_call <- xp_call_name(bad_expr)
    lint_message <- paste(
      "Use the `...` argument of system.file() to expand paths,",
      'e.g. system.file("data", "model.csv", package = "myrf") instead of',
      ifelse(
        outer_call == "system.file",
        'system.file(file.path("data", "model.csv"), package = "myrf")',
        'file.path(system.file(package = "myrf"), "data", "model.csv")'
      )
    )

    xml_nodes_to_lints(bad_expr, source_expression, lint_message, type = "warning")
  })
}
