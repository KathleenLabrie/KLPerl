#################################################################
#
# Makefile for Iraf::System Module
#
# Front end for IRAF's System package.
#
# Perl modules required: Iraf.pm
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

EPREFIX = $(PREFIX)/iraf/system
IPREFIX = $(INCLDIR)
DPREFIX = $(EPREFIX)/doc

#### Compiler Variable Definitions ####
PERL = perl

################## DO NOT EDIT BELOW THIS LINE #################
REQMOD = Iraf.pm
IRAFPKG = x_system.e

PKGNAME = Iraf-System
MODNAME = System.pm
BASIC_FILES = Makefile Changes TODO
DOCS = doc.txt
VERSION = 0
RELEASE = $(VERSION).1.1

#### Object Definitions ####
SRC = dellist.pl
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
# Look for IRAF pkg
	@rm -f scratch
	@echo '#!'`which perl` > scratch
	@grep 'IRAFBIN =' $(INCLDIR)/Iraf.pm >> scratch
	@echo '$$OS = $(OS);' >> scratch
	@for pkg in $(IRAFPKG) ; do \
	  grep $$pkg $(INCLDIR)/Iraf.pm >> scratch; \
	done
	@for pkg in $(patsubst x_%.e,%,$(IRAFPKG)) ; do \
	  echo 'print "$$pkg_'$$pkg'\n";' >> scratch; \
	done
	@chmod 0755 scratch
	@for pkg in `./scratch` ; do \
	  echo -n "Looking for '$$pkg' ... "; \
	  if [ -f $$pkg ]; then \
	  	echo "found"; \
	  else \
	  	echo "not found"; \
		exit 1; \
	  fi; \
	done
	@rm -f scratch	    
# Configure module
	@echo -n "Configuring module ... "
	@sed "s!\$$EPREFIX='.*';!\$$EPREFIX='$(EPREFIX)';!" $(MODNAME) > tmp
	@if [ -s tmp ]; then \
	  mv -f tmp $(MODNAME); \
	else \
	  echo "Error configuring $(MODNAME)"; \
	fi
	@echo "done"
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
