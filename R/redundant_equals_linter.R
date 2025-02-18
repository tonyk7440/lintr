#' Block usage of `==`, `!=` on logical vectors
#'
#' Testing `x == TRUE` is redundant if `x` is a logical vector. Wherever this is
#'   used to improve readability, the solution should instead be to improve the
#'   naming of the object to better indicate that its contents are logical. This
#'   can be done using prefixes (is, has, can, etc.). For example, `is_child`,
#'   `has_parent_supervision`, `can_watch_horror_movie` clarify their logical
#'   nature, while `child`, `parent_supervision`, `watch_horror_movie` don't.
#'
#' @examples
#' # will produce lints
#' lint(
#'   text = "if (any(x == TRUE)) 1",
#'   linters = redundant_equals_linter()
#' )
#'
#' lint(
#'   text = "if (any(x != FALSE)) 0",
#'   linters = redundant_equals_linter()
#' )
#'
#' # okay
#' lint(
#'   text = "if (any(x)) 1",
#'   linters = redundant_equals_linter()
#' )
#'
#' lint(
#'   text = "if (!all(x)) 0",
#'   linters = redundant_equals_linter()
#' )
#'
#' @evalRd rd_tags("redundant_equals_linter")
#' @seealso [linters] for a complete list of linters available in lintr. \cr
#'   [outer_negation_linter()]
#' @export
redundant_equals_linter <- function() {
  xpath <- paste0(
    c("//EQ", "//NE"),
    "/parent::expr/expr[NUM_CONST[text() = 'TRUE' or text() = 'FALSE']]/parent::expr",
    collapse = " | "
  )

  Linter(function(source_expression) {
    if (!is_lint_level(source_expression, "expression")) {
      return(list())
    }

    xml <- source_expression$xml_parsed_content

    bad_expr <- xml2::xml_find_all(xml, xpath)
    op <- xml2::xml_text(xml2::xml_find_first(bad_expr, "*[2]"))

    xml_nodes_to_lints(
      bad_expr,
      source_expression = source_expression,
      lint_message = paste(
        "Using", op, "on a logical vector is redundant.",
        "Well-named logical vectors can be used directly in filtering.",
        "For data.table's `i` argument, wrap the column name in (), like `DT[(is_treatment)]`."
      ),
      type = "warning"
    )
  })
}
