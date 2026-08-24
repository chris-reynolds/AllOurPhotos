# TODO

## Bugs

- **aopFullExport `/export_snap/{id}` crashes uvicorn worker on snap 17554** ("2015-06-08 08.57.53.jpg") — PIL pixel-decode crash during rotate/save (not piexif). Client falls back to raw download without baked-in EXIF. Low priority — not worth fixing unless EXIF is needed on that specific file.
- **[unconfirmed] YearGrid/monthgrid search not repainting** — one observed instance where searching from the monthgrid didn't trigger a repaint. Not yet determined whether it was a failed fetch (data never came back) or a failed paint (data arrived but UI didn't update). Needs repro before investigating.

## Test suite

- **`pyserver/src/test/test_aopsync.py` has 5 unimplemented stub tests** (`test_add_file_folder`, `test_add_thumbnail`, `test_add_metadata`, `test_add_to_db_correctly`, `test_location_deduced_and_stored`) that just `raise Exception('To do')`.
- **4 tests are non-idempotent and fail with `409 Duplicate entry` on repeat runs** (`test_existance_check1_using_filename_date_modified`, `test_samsung_post`, `test_huawei_post`, `test_video`) — the `clean` fixture that should reset test data (`tu.clear_testdata()`) is commented out at `test_aopsync.py:29-31`, so re-running the suite against a DB that already has the fixture files fails on the app's own duplicate-file check.
