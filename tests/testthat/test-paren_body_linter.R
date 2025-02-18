testthat::test_that("paren_body_linter returns correct lints", {
  linter <- paren_body_linter()
  lint_msg <- "There should be a space between a right parenthesis and a body expression."

  # No space after the closing parenthesis prompts a lint
  expect_lint("function()test", lint_msg, linter)
  expect_lint("print('hello')\nx <- function(x)NULL\nprint('hello')", lint_msg, linter)
  expect_lint("if (TRUE)test", lint_msg, linter)
  expect_lint("while (TRUE)test", lint_msg, linter)
  expect_lint("for (i in seq_along(1))test", lint_msg, linter)

  # A space after the closing parenthesis does not prompt a lint
  expect_lint("function() test", NULL, linter)

  # Symbols after the closing parenthesis of a function call do not prompt a lint
  expect_lint("head(mtcars)$cyl", NULL, linter)

  # paren_body_linter returns the correct line number
  expect_lint(
    "print('hello')\nx <- function(x)NULL\nprint('hello')",
    list(line_number = 2L),
    linter
  )

  expect_lint(
    "function()test",
    list(
      line_number = 1L,
      column_number = 11L,
      type = "style",
      line = "function()test",
      ranges = list(c(11L, 14L))
    ),
    linter
  )

  # paren_body_linter does not lint when the function body is defined on a new line
  expect_lint("function()\n  test", NULL, linter)

  # paren_body_linter does not lint comments
  expect_lint("#function()test", NULL, linter)

  # multiple lints on the same line
  expect_lint("function()if(TRUE)while(TRUE)test", list(lint_msg, lint_msg, lint_msg), linter)

  # No space after the closing parenthesis of an anonymous function prompts a lint
  skip_if_not_r_version("4.1.0")
  expect_lint("\\()test", lint_msg, linter)
})

test_that("multi-line versions are caught", {
  expect_lint(
    trim_some("
      function(var
                  )x
    "),
    rex::rex("There should be a space between a right parenthesis and a body expression."),
    paren_body_linter()
  )
  expect_lint(
    trim_some("
      if (cond
              )x
    "),
    rex::rex("There should be a space between a right parenthesis and a body expression."),
    paren_body_linter()
  )
  expect_lint(
    trim_some("
      while (cond
                 )x
    "),
    rex::rex("There should be a space between a right parenthesis and a body expression."),
    paren_body_linter()
  )

  skip_if_not_r_version("4.1.0")
  expect_lint(
    trim_some("
      \\(var
            )x
    "),
    rex::rex("There should be a space between a right parenthesis and a body expression."),
    paren_body_linter()
  )
})
