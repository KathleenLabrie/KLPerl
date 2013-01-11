#################################################################
#
# Makefile for Img::Header Module
#
# Access FITS image headers.
#
# Perl modules required:
# Other packages required: KLimgutil [C]
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

EPREFIX = $(PREFIX)/img/header
IPREFIX = $(INCLDIR)
DPREFIX = $(EPREFIX)/doc

C_PREFIX = /home/labrie/prgc
C_KLIMGUTIL = $(C_PREFIX)/img/util

#### Compiler Variable Definitions ####
PERL = perl

################## DO NOT EDIT BELOW THIS LINE #################
#REQSUBMOD = CFHT
REQMOD = 
REQCPKG = KLimgutil

PKGNAME = Img-Header
MODNAME = $(addsuffix .pm,$(notdir $(subst -,/,$(PKGNAME))))
BASIC_FILES = Makefile Changes TODO conf-template.pl
DOCS = doc.txt
VERSION = 0
RELEASE = $(VERSION).1.1

#### Object Definitions ####
SRC = 
HEADERS = $(MODNAME)

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
# Look for required Perl Modules
	@for mod in $(REQMOD) ; do \
	  echo -n "Looking for Perl module '$$mod' ... "; \
	  if [ -f $(INCLDIR)/$$mod ]; then \
	  	echo "found"; \
	  else \
	  	echo "not found"; \
		exit 1; \
	  fi; \
	done
# Configure module
	@echo -n "Configuring module ... "
	@echo '#!'`which perl`' -w' > scratch
	@echo "%hash=('^.EPREFIX\s*(=\s*\'.*\';)' => '= \'$(EPREFIX)\';'," \
			>> scratch
	@echo "'^.OS\s*(=\s*\'.*\';)' => '= \'$(OS)\';'," \
			>> scratch
	@echo "'^.C_PREFIX\s*(=\s*\'.*\';)' => '= \'$(C_PREFIX)\';'," \
			>> scratch
	@echo "'^.C_KLIMGUTIL\s*(=\s*\'.*\';)'  => '= \'$(C_KLIMGUTIL)\';');" \
			>> scratch
	@echo "open(FILE,\"<$(MODNAME)\");" >> scratch
	@cat scratch conf-template.pl > conf.pl
	@rm -f scratch
	@chmod 0755 conf.pl
	@./conf.pl > tmp
	@if [ -s tmp ]; then \
	  mv -f tmp $(MODNAME); \
	else \
	  echo "ERROR: Error configuring the module."; \
	  exit 1; \
	fi
	@rm -f conf.pl
	@echo "done"
# Look for C packages
	@for pkg in $(REQCPKG); do \
	  echo "Looking for C package $$pkg ... "; \
	  for dir in `perl -n -e "if (/Begin $$pkg/) {\\$$B=1;next;}" \
	          -e "elsif (/End $$pkg/) {exit(0);}" \
		  -e "if (\\$$B==1) {/.*=\s*'(.*)';/;print \"\\$$1 \";}" \
		  $(MODNAME)`; do \
	    echo -n "	$$dir ... "; \
	    if [ -s $$dir ]; then \
	  	echo "found"; \
	    else \
	  	echo "not found"; \
		exit 1; \
	    fi; \
	  done; \
	done
# Configure scripts
	@echo -n "Configuring scripts ... "
	@for script in $(SRC) ; do \
	  sed "s!use lib qw(.*)!use lib qw($(INCLDIR))!" $$script > tmp; \
	  if [ -s tmp ]; then \
	    mv -f tmp $$script; \
	  else \
	    echo "Error configuring $$script"; \
	  fi; \
	done
	@echo "done"

## Installing ##
.PHONY: install
install :
	@install -d -m 0755 $(EPREFIX)
	@for script in $(SRC) ; do \
	  install -m 0755 $$script $(EPREFIX)/; \
	done
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

### End of Makefile ###
