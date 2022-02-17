# Marka - Markup/LaTeX Rendering Made Simple
`marka` is a tool for making it more convenient to work with Pandoc Markdown.
This is to support the complete replacement of normal LaTeX workflows with Markdown, without loosing any features.

## Usage
Marka consists of two tools: `marka` and `marka-combine`
The combiner is just like the preprocessor in C and is already called when using `marka` normally.
To compile a file with marka, the basic call syntax is `marka file.md`, but for day-to-day rendering it is more convenient to use the `marka -w file.md` syntax, which will automatically rerender the file when any included file is changed.

## Combination
The only way Marka Markdown differs from Pandoc Markdown, is the inclusion of the `€[./file]` construct, which recursively adds files to the project, making it more natural to include source-files or other markdown files.
This does break a bit with the convention of Markdown being readable as just a textfile, but is included because Marka Markdown is intended to replace LaTeX and many LaTeX project are too big to conveniently exist as a single file.
It also allows the inclusion of parts of source-code or other documents, which helps keep a single-source-of-truth workflow, where external data is not copied into the documentation manually, which can result in mismatches between the document version of data and the real data.

## Building
Marka is set up to build via the Crystal build tool Shards, so a simple `shards install && shards build` should produce the binaries.
There is also support for building via Nix, so a simple `nix build` will produce a derivation.
