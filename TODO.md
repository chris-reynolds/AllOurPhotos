# TODO

## Bugs

- **aopFullExport `/export_snap/{id}` crashes uvicorn worker on snap 17554** ("2015-06-08 08.57.53.jpg") — PIL pixel-decode crash during rotate/save (not piexif). Client falls back to raw download without baked-in EXIF. Low priority — not worth fixing unless EXIF is needed on that specific file.
- **[unconfirmed] YearGrid/monthgrid search not repainting** — one observed instance where searching from the monthgrid didn't trigger a repaint. Not yet determined whether it was a failed fetch (data never came back) or a failed paint (data arrived but UI didn't update). Needs repro before investigating.
