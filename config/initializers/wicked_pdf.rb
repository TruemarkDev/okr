# The `lib/wkhtmltopdf` binary this used to point at is long gone; the
# `wkhtmltopdf-binary` gem now bundles a platform binary and puts it on PATH
# (`wkhtmltopdf`) via its own bin stub, so let wicked_pdf auto-detect it
# instead of hardcoding a stale path (roadmap Task 11).
WickedPdf.config = {}

