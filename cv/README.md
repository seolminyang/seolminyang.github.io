# Quarto CV workflow

`cv/cv.qmd` is the single source of truth for the CV.

From the repository root, run:

```bash
Rscript scripts/render_cv.R
```

This command regenerates both:

- `_pages/cv.md` — the GitHub Pages / Academic Pages CV page
- `files/Seolmin_Yang_CV.pdf` — the downloadable PDF

Do not manually edit the generated `_pages/cv.md` or PDF. Edit `cv/cv.qmd`, then render again.
