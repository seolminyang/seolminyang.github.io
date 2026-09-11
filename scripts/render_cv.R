# Render cv/cv.qmd into a polished PDF and a GitHub Pages CV page.
# Single source of truth: cv/cv.qmd

source_file <- "cv/cv.qmd"
pdf_target <- "files/Seolmin_Yang_CV.pdf"
web_file <- "_pages/cv.md"

if (!file.exists(source_file)) stop("Cannot find ", source_file)

quarto <- Sys.which("quarto")
if (quarto == "") stop("Quarto is not available on PATH.")

# ---- 1. Build the PDF ------------------------------------------------------
status <- system2(
  quarto,
  c("render", source_file, "--to", "pdf", "--output", "Seolmin_Yang_CV.pdf")
)
if (status != 0L) stop("Quarto PDF rendering failed.")

# With Quarto, --output is resolved relative to the project working directory.
# Check both common locations so the script is robust across Quarto versions.
pdf_candidates <- c(
  "Seolmin_Yang_CV.pdf",
  file.path(dirname(source_file), "Seolmin_Yang_CV.pdf")
)
rendered_pdf <- pdf_candidates[file.exists(pdf_candidates)][1]
if (is.na(rendered_pdf)) {
  stop("Expected rendered PDF was not found. Checked: ", paste(pdf_candidates, collapse = ", "))
}

dir.create(dirname(pdf_target), recursive = TRUE, showWarnings = FALSE)
if (!file.copy(rendered_pdf, pdf_target, overwrite = TRUE)) {
  stop("Failed to copy rendered PDF to ", pdf_target)
}
if (normalizePath(rendered_pdf, mustWork = FALSE) != normalizePath(pdf_target, mustWork = FALSE)) {
  unlink(rendered_pdf)
}

# ---- 2. Build the Jekyll Markdown page ------------------------------------
# The website uses the same qmd body. We remove PDF-only wrapper lines and
# turn cv-entry dates into a compact right-aligned HTML date.
x <- readLines(source_file, warn = FALSE, encoding = "UTF-8")
yaml_delims <- which(trimws(x) == "---")
if (length(yaml_delims) < 2L) stop("Could not locate YAML front matter in ", source_file)
body <- x[(yaml_delims[2L] + 1L):length(x)]

out <- character()
in_header <- FALSE
for (line in body) {
  if (grepl('^::: \\{\\.cv-header\\}', line)) {
    in_header <- TRUE
    next
  }
  if (in_header && trimws(line) == ":::") {
    in_header <- FALSE
    next
  }
  if (in_header) next

  m <- regexec('^::: \\{\\.cv-entry date="([^"]*)"\\}', line)
  hit <- regmatches(line, m)[[1]]
  if (length(hit) > 0L) {
    out <- c(out, sprintf('<div class="cv-entry"><span class="cv-date">%s</span>', hit[2]))
    next
  }
  if (grepl('^::: \\{\\.cv-pub\\}', line)) {
    out <- c(out, '<div class="cv-pub">')
    next
  }
  if (trimws(line) == ":::") {
    out <- c(out, '</div>')
    next
  }
  out <- c(out, line)
}

# Demote Quarto H2 sections to top-level Markdown headings for the page.
out <- sub('^## ', '# ', out)

jekyll_header <- c(
  "---",
  "layout: archive",
  'title: "CV"',
  "permalink: /cv/",
  "author_profile: true",
  "redirect_from:",
  "  - /resume",
  "---",
  "",
  "{% include base_path %}",
  "",
  "[Download CV (PDF)](/files/Seolmin_Yang_CV.pdf)",
  ""
)

web_css <- c(
  '<style>',
  '.cv-entry { position: relative; padding-right: 9.5rem; margin: 0 0 0.9rem 0; }',
  '.cv-date { position: absolute; right: 0; top: 0; white-space: nowrap; }',
  '.cv-pub { margin: 0 0 0.65rem 0; padding-left: 0.8rem; text-indent: -0.8rem; }',
  '@media (max-width: 700px) {',
  '  .cv-entry { padding-right: 0; }',
  '  .cv-date { position: static; display: block; margin-bottom: 0.15rem; font-style: italic; }',
  '}',
  '</style>',
  ''
)

dir.create(dirname(web_file), recursive = TRUE, showWarnings = FALSE)
writeLines(c(jekyll_header, web_css, out), web_file, useBytes = TRUE)

message("Updated:")
message("  ", web_file)
message("  ", pdf_target)
