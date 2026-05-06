# Top-level Linux makefile for ka9q-web package
# Copyright 2026, Phil Karn, KA9Q
.DEFAULT_GOAL := all

BUILD 	      ?= release
prefix        ?= /usr/local
exec_prefix   ?= $(prefix)
bindir        ?= $(exec_prefix)/bin
sbindir       ?= $(exec_prefix)/sbin
libdir        ?= $(exec_prefix)/lib
datadir       ?= $(prefix)/share
confdir	      ?= /etc/radio
localstatedir ?= /var
pkgdatadir    ?= $(datadir)/ka9q-radio
pkglibdir     ?= $(libdir)/ka9q-radio
statedir      ?= $(localstatedir)/lib/ka9q-radio


UNAME_S := $(shell uname -s)

export prefix exec_prefix bindir sbindir libdir datadir sysconfdir
export localstatedir pkgdatadir pkglibdir statedir mandir

# for production
DOPTS=-DNDEBUG=1 -O3

# for debugging
#DOPTS=-g

KA9QOBJS = misc.o multicast.o rtp.o status.o decode_status.o

COPTS=-march=native -std=gnu11 -pthread -Wall -funsafe-math-optimizations -D_GNU_SOURCE=1
INCLUDES=-Ika9q-sources

CFLAGS=$(DOPTS) $(COPTS)
CPPFLAGS=$(INCLUDES)

all: ka9q-web

ka9q-web: ka9q-web.o libka9q.a
	$(CC) -o $@ $^ -lonion -lbsd -lm

install: ka9q-web
	install -d -m 0755 $(DESTDIR)$(sbindir)
	install -m 755 $^ $(DESTDIR)$(sbindir)
	install -d -m 0755 $(DESTDIR)$(pkgdatadir)/html/
	install -m 644 -D html/* -t $(DESTDIR)$(pkgdatadir)/html/

install-config:
	install -b -m 644 config/* $(DESTDIR)$(confdir)

clean:
	-rm -f ka9q-web *.o *.d

.PHONY: clean all install

libka9q.a: $(KA9QOBJS)
	ar rv $@ $^
	ranlib $@

# handle quotes inside GIT summary messages, etc. Suggested by ChatGPT
esc = sed 's/\\/\\\\/g; s/"/\\"/g'
config_paths.h: Makefile
	echo "make $@"
	@printf '#ifndef _CONFIG_PATHS_H\n' > $@
	@printf '#define _CONFIG_PATHS_H 1\n' >> $@
	@printf '#define CONFDIR "%s"\n' '$(confdir)' >> $@
	@printf '#define STATEDIR "%s"\n' '$(statedir)' >> $@
	@printf '#define PKGDATADIR "%s"\n' '$(pkgdatadir)' >> $@
	@printf '#define PKGLIBDIR "%s"\n' '$(pkglibdir)' >> $@
	@printf '#define GIT_HASH "%s"\n' "$$(git rev-parse HEAD | $(esc))" >> $@
	@printf '#define GIT_TIME "%s"\n' "$$(git show -s --format=%ci | $(esc))" >> $@
	@printf '#define GIT_BRANCH "%s"\n' "$$(git log --pretty=format:%d -n 1 | $(esc))" >> $@
	@printf '#define GIT_SUMMARY "%s"\n' "$$(git log -1 --format=%s | $(esc))" >> $@
	@printf '#define GIT_VERSION "%s"\n' "$$(git describe --always --dirty --tags | $(esc))" >> $@
	@printf '#define GIT_REMOTE_URL "%s"\n' "$$(git remote get-url origin  | $(esc))" >> $@
	@printf '#endif\n' >> $@

%.o: %.c config_paths.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c -o $@ $<

DEPS = $(CFILES:.c=.d) $(OBJS:.o=.d)
-include $(DEPS)
