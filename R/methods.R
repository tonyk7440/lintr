#' @export
print.lint <- function(x, ...) {
  if (requireNamespace("crayon", quietly = TRUE)) {
    color <- switch(x$type,
      warning = crayon::magenta,
      error = crayon::red,
      style = crayon::blue,
      crayon::bold
    )
    emph <- crayon::bold
  } else {
    # nocov start
    color <- identity
    emph <- identity
    # nocov end
  }

  cat(
    sep = "",
    emph(
      x$filename, ":",
      as.character(x$line_number), ":",
      as.character(x$column_number), ": ",
      sep = ""
    ),
    color(x$type, ": ", sep = ""),
    "[", x$linter, "] ",
    emph(x$message), "\n",
    # swap tabs for spaces for #528 (sorry Richard Hendricks)
    chartr("\t", " ", x$line), "\n",
    highlight_string(x$message, x$column_number, x$ranges),
    "\n"
  )
  invisible(x)
}

markdown <- function(x, info, ...) {
  cat(
    sep = "",
    "[", x$filename, ":",
    as.character(x$line_number), ":",
    as.character(x$column_number), ":", "]",
    "(",
    paste(
      sep = "/",
      "https://github.com",
      info$user,
      info$repo,
      "blob",
      info$commit,
      x$filename
    ), "#L", x$line_number,
    ")",
    " ",
    "*", x$type, ":", "* ",
    "[", x$linter, "] ",
    "**", x$message, "**\n",
    "```r\n\U200B", # we use a zero width unicode character here so that Github
    # does not strip the leading whitespace
    x$line, "\n",
    highlight_string(x$message, x$column_number, x$ranges),
    "\n```\n"
  )
  invisible(x)
}

#' @export
print.lints <- function(x, ...) {
  use_rstudio_source_markers <- getOption("lintr.rstudio_source_markers", TRUE) &&
    requireNamespace("rstudioapi", quietly = TRUE) &&
    rstudioapi::hasFun("sourceMarkers")

  github_annotation_project_dir <- getOption("lintr.github_annotation_project_dir", "")

  if (length(x)) {
    inline_data <- x[[1L]][["filename"]] == "<text>"
    if (!inline_data && use_rstudio_source_markers) {
      rstudio_source_markers(x)
    } else if (in_github_actions()) {
      github_actions_log_lints(x, project_dir = github_annotation_project_dir)
    } else {
      if (in_ci() && settings$comment_bot) {
        info <- ci_build_info()

        lint_output <- trim_output(
          paste0(
            collapse = "\n",
            capture.output(invisible(lapply(x, markdown, info, ...)))
          )
        )

        github_comment(lint_output, info, ...)
      }
      lapply(x, print, ...)
    }

    if (isTRUE(settings$error_on_lint)) {
      quit("no", 31L, FALSE) # nocov
    }
  } else if (use_rstudio_source_markers) {
    # Empty lints: clear RStudio source markers
    rstudio_source_markers(x)
  }
  invisible(x)
}

trim_output <- function(x, max = 65535L) {
  # if x is less than the max, just return it
  if (length(x) <= 0L || nchar(x) <= max) {
    return(x)
  }

  # otherwise trim x to the max, then search for the lint starts
  x <- substr(x, 1L, max)

  re <- rex::rex(
    "[", except_some_of(":"), ":", numbers, ":", numbers, ":", "]",
    "(", except_some_of(")"), ")",
    space,
    "*", or("style", "warning", "error"), ":", "*",
    except_some_of("\r\n"), newline,
    except_some_of("\r\n"), newline,
    except_some_of("\r\n"), newline,
    except_some_of("\r\n"), newline,
    except_some_of("\r\n"), newline
  )

  lint_starts <- rex::re_matches(x, re, global = TRUE, locations = TRUE)[[1L]]

  # if at least one lint ends before the cutoff, cutoff there, else just use
  # the cutoff
  last_end <- lint_starts[NROW(lint_starts), "end"]
  if (!is.na(last_end)) {
    substr(x, 1L, last_end)
  } else {
    x
  }
}

#' @export
names.lints <- function(x, ...) {
  vapply(x, `[[`, character(1L), "filename")
}

#' @export
split.lints <- function(x, f = NULL, ...) {
  if (is.null(f)) f <- names(x)
  splt <- split.default(x, f)
  for (i in names(splt)) class(splt[[i]]) <- "lints"
  return(splt)
}

#' @export
as.data.frame.lints <- function(x, row.names = NULL, optional = FALSE, ...) { # nolint: object_name. (row.names, #764)
  data.frame(
    filename = vapply(x, `[[`, character(1L), "filename"),
    line_number = vapply(x, `[[`, integer(1L), "line_number"),
    column_number = vapply(x, `[[`, integer(1L), "column_number"),
    type = vapply(x, `[[`, character(1L), "type"),
    message = vapply(x, `[[`, character(1L), "message"),
    line = vapply(x, `[[`, character(1L), "line"),
    linter = vapply(x, `[[`, character(1L), "linter"),
    stringsAsFactors = FALSE
  )
}

#' @export
`[.lints` <- function(x, ...) {
  attrs <- attributes(x)
  x <- unclass(x)
  x <- x[...]
  attributes(x) <- attrs
  x
}

#' @export
summary.lints <- function(object, ...) {
  filenames <- vapply(object, `[[`, character(1L), "filename")
  types <- factor(vapply(object, `[[`, character(1L), "type"),
    levels = c("style", "warning", "error")
  )
  tbl <- table(filenames, types)
  filenames <- rownames(tbl)
  res <- as.data.frame.matrix(tbl, stringsAsFactors = FALSE, row.names = NULL)
  res$filenames <- filenames %||% character()
  nms <- colnames(res)
  res[order(res$filenames), c("filenames", nms[nms != "filenames"])]
}
