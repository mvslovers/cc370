# Builds the cc370 manuals.  Needs typst and the bookmaster submodule
# (git submodule update --init docs/books/bookmaster).

TYPST ?= typst
BM    := bookmaster
BOOKS := ml01-0002.pdf

.PHONY: all check clean

all: check $(BOOKS)

%.pdf: %.typ $(wildcard ref/*.typ ex/*/* syntax/*.txt) $(BM)/bookmaster.typ
	$(TYPST) compile --root . --font-path $(BM)/fonts --ignore-system-fonts $< $@

check:
	python3 $(BM)/tools/check-syntax.py syntax/*.txt

clean:
	rm -f *.pdf
