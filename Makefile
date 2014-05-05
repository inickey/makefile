TARGET     = makefile
LIBS       = 
VERSION    = $(shell ./version.sh)
ADD_CFLAGS =
ADD_LFLAGS =
EXTRA_DIST =

CC         = $(shell which cc)
PKG        = $(shell which pkg-config)

PKG_CFLAGS = $(shell $(PKG) $(LIBS) --cflags)
PKG_LFLAGS = $(shell $(PKG) $(LIBS) --libs)
DBG_CFLAGS = -ggdb -g -DDEBUG -Wall
DBG_LFLAGS = -ggdb -g -Wall
CFLAGS     = $(ADD_CFLAGS) $(PKG_CFLAGS) \
             -DVERSION=$(VERSION)
LFLAGS     = $(ADD_LFLAGS) $(PKG_LFLAGS)

OBJ_DIR    = .obj/
DIST_FILES = Makefile .version version.sh install.sh \
             README.md AUTHORS COPYING ChangeLog.txt \
             $(wildcard *.c) $(wildcard *.h) $(EXTRA_DIST)

SOURCES    = $(wildcard *.c)
OBJECTS    = $(addprefix $(OBJ_DIR)/, $(SOURCES:.c=.o))

QUIET      = @

ALL        = all
DEBUG      = debug
REBUILD    = rebuild
DREBUILD   = drebuild
CLEAN      = clean
CHANGELOG  = ChangeLog.txt
DISTCLEAN  = distclean
DIST       = dist
INSTALL    = install

$(ALL): $(TARGET)

$(TARGET): $(OBJECTS)
	$(QUIET) echo "  LD	$@"
	$(QUIET) $(CC) $^ $(LFLAGS) -o $@

$(DEBUG): CFLAGS += $(DBG_CFLAGS)
$(DEBUG): LFLAGS += $(DBG_LFLAGS)
$(DEBUG): $(TARGET)

$(OBJ_DIR)/%.o: %.c
	$(QUIET) mkdir -p $(OBJ_DIR)
	$(QUIET) echo "  CC	$<	$(notdir $@)"
	$(QUIET) $(CC) -c $< $(CFLAGS) -o $@ -MMD

.PHONY: $(CLEAN) $(DISTCLEAN) $(DIST) $(REBUILD) $(DREBUILD) $(INSTALL) \
        $(CHANGELOG)

$(CLEAN):
	$(QUIET) rm -f $(wildcard $(OBJ_DIR)/*.d)
	$(QUIET) rm -f $(wildcard $(OBJ_DIR)/*.o)
	$(QUIET) rm -f $(TARGET)

$(DISTCLEAN): $(CLEAN)
	$(QUIET) rm -rf $(OBJ_DIR) $(wildcard $(TARGET)-*.tar.gz)
	$(QUIET) rm -f $(CHANGELOG)

$(REBUILD):  $(CLEAN) $(TARGET)
$(DREBUILD): $(CLEAN) $(DEBUG)

$(CHANGELOG):
	$(QUIET) if [ -d .git ] ; then \
		git log `git tag`.. --pretty=format:"* %ad | %s%d [%an]" \
		--date=short > $@ ; \
	fi
	$(QUIET) echo "" >> $@

$(DIST): DIST_NAME = $(TARGET)-$(VERSION)-$(shell date +%d%m%y).tar.gz
$(DIST): CURR_PWD  = $(shell pwd)
$(DIST): $(CHANGELOG)
$(DIST):
	$(QUIET) echo "Making $(DIST_NAME)"
	$(QUIET) mkdir $(CURR_PWD)/dist/$(TARGET) -p
	$(QUIET) cp $(DIST_FILES) $(CURR_PWD)/dist/$(TARGET) -f
	$(QUIET) cd $(CURR_PWD)/dist/ && \
                 tar -czvf $(DIST_NAME) $(TARGET) > /dev/null
	$(QUIET) mv $(CURR_PWD)/dist/$(DIST_NAME) $(CURR_PWD) && \
                 rm -rf dist

$(INSTALL):
	$(QUIET) echo "Installing $(TARGET)..."
	$(QUIET) ./install.sh --target $(TARGET) --version $(VERSION)

include $(wildcard $(OBJ_DIR)/*.d)
