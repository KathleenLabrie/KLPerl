#################################################################
#
# Makefile for Iraf Module
#
# Basic module for IRAF front-end routines.  Sets several
# environment dependent variables.
# Does not do much by itself, but required by add-on modules.
#
# Perl modules required: none
# Other packages required: none
# Libraries required: KLimgutil [C]
#
# Coding language: Perl
# Compiler: perl
# OS: Redhat Linux
#
#################################################################

MAKE = make
GZIP = gzip -S .gz

#### Environment Variable Definitions ####
OS = redhat
PREFIX = /home/labrie/prgp
INCLDIR = $(PREFIX)/include

EPREFIX = $(PREFIX)/iraf
IPREFIX = $(INCLDIR)
DPREFIX = $(EPREFIX)/doc

IRAFDIR = /iraf/irafbin

C_PREFIX = /home/labrie/prgc
C_LIBDIR = $(C_PREFIX)/lib

REQMOD =
REQLIB = KLimgutil


#### Compiler Variable Definitions ####
PERL = perl

################## DO NOT EDIT BELOW THIS LINE #################
PKGNAME = Iraf
BASIC_FILES = Makefile Changes TODO
DOCS = doc.txt
VERSION = 0
RELEASE = $(VERSION).1.2

#### Object Definitions ####
SRC =
HEADERS = Iraf.pm

#### Rule Definitions ####

main: configure

.PHONY: configure
configure:
# Look for Perl
	@echo -n "Looking for Perl ... "
	@if (which perl > /dev/null 2>&1); then \
		echo "found"; \
	else \
		echo "not found"; \
		exit 1; \
	fi
# Look for IRAF
	@echo -n "Looking for IRAF ... "
	@if (which cl > /dev/null 2>&1); then \
		echo "found"; \
	else \
		echo "not found"; \
		exit 1; \
	fi
# Look for C libraries
	@for lib in $(REQLIB); do \
	  echo -n "Looking for $$lib ... "; \
	  if [ -f $(C_LIBDIR)/lib$$lib.a ]; then \
	  	echo "found"; \
	  else \
	  	echo "not found"; \
		exit 1; \
	  fi; \
	done
# Configure module
	@echo -n "Configuring module ... "
	@sed "s!\$$EPREFIX='.*';!\$$EPREFIX='$(EPREFIX)';!" $(PKGNAME).pm > tmp
	@if [ -s tmp ]; then \
	  mv -f tmp $(PKGNAME).pm; \
	else \
	  echo "Error configuring $(PKGNAME).pm"; \
	fi	
	@sed "s!\$$OS='.*';!\$$OS='$(OS)';!" $(PKGNAME).pm > tmp
	@if [ -s tmp ]; then \
	  mv -f tmp $(PKGNAME).pm; \
	else \
	  echo "Error configuring $(PKGNAME).pm"; \
	fi
	@sed "s!\$$IRAFDIR = \".*\"!\$$IRAFDIR = \"$(IRAFDIR)\"!" \
		$(PKGNAME).pm > tmp
	@if [ -s tmp ]; then \
	  mv -f tmp $(PKGNAME).pm; \
	else \
	  echo "Error configuring $(PKGNAME).pm"; \
	fi
	@sed "s!\$$CDIR = '.*'!\$$CDIR = '$(C_PREFIX)'!" $(PKGNAME).pm > tmp
	@if [ -s tmp ]; then \
	  mv -f tmp $(PKGNAME).pm; \
	else \
	  echo "Error configuring $(PKGNAME).pm"; \
	fi
	@echo "done"

## Installing ##
.PHONY: install
install :
	@install -d -m 0755 $(IPREFIX)/$(dir $(subst -,/,$(PKGNAME)))
	@for mod in $(HEADERS) ; do \
	  install -m 0644 $$mod $(IPREFIX)/$(dir $(subst -,/,$(PKGNAME)))/; \
	done
	@install -d -m 0755 $(DPREFIX)
	@for file in $(BASIC_FILES) $(DOCS) ; do \
	  install -m 0644 $$file $(DPREFIX)/; \
	done

## Packaging ##
.PHONY: package-src
package-src:
	tar cvf $(PKGNAME)-$(RELEASE).tar $(BASIC_FILES) $(DOCS) $(SRC) \
	$(HEADERS)
	$(GZIP) $(PKGNAME)-$(RELEASE).tar

## Cleaning ##
.PHONY: clean
clean:
	echo "Nothing to clean"

### End of Makefile
