# Builds the cc370 manuals.  Needs typst and the bookmaster submodule
# (git submodule update --init docs/books/bookmaster).

TYPST ?= typst
BM    := bookmaster
# The PDF carries the edition: ml01-0002-0.pdf is the first edition of
# ML01-0002.  Bump the suffix together with the number on the title page.
BOOKS := ml01-0001-0.pdf ml01-0002-0.pdf

.PHONY: all check clean

all: check $(BOOKS)

ml01-0001-%.pdf: ml01-0001.typ $(wildcard guide/*.typ ex/*/* syntax/*.txt) $(BM)/bookmaster.typ
	$(TYPST) compile --root . --font-path $(BM)/fonts --ignore-system-fonts $< $@

ml01-0002-%.pdf: ml01-0002.typ $(wildcard ref/*.typ ex/*/* syntax/*.txt) $(BM)/bookmaster.typ
	$(TYPST) compile --root . --font-path $(BM)/fonts --ignore-system-fonts $< $@

check:
	python3 $(BM)/tools/check-syntax.py syntax/*.txt

clean:
	rm -f *.pdf
