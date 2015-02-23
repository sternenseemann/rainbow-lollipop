

# src files. ein find . -name *.vala sollte auch gehen
SRC = src/alaia.vala \
      src/database.vala \
      src/track.vala \
      src/empty_track.vala \
      src/history_track.vala \
      src/tracklist.vala \
      src/nodes.vala \
      src/site_node.vala \
      src/download_node.vala \
      src/config.vala \
      src/ipc.vala \
      src/session_select.vala \
      src/authentication_dialog.vala \
      src/history.vala \
      src/searchengine.vala \

# LIBS werden fuer valac und gcc aufgeloest. VALALIBS und CLIBS
# jeweils nur fuer valac und gcc.
# z.b. valac -pkg libpq  || gcc -lpq
VALALIBS =  
CLIBS = 
LIBS = gtk+-3.0 clutter-1.0 clutter-gtk-1.0 webkit2gtk-4.0 gee-1.0 libzmq sqlite3
EXT_LIBS = webkit2gtk-web-extension-4.0 gee-1.0 libzmq

CC = gcc

# Vala compilerflags
VFLAGS = --thread -D DEBUG --vapidir=vapi

# programmname.
TARGET = alaia
EXTENSION = alaiawebextension

######################################################
# haende weg. alles andere wird automatisch gemacht !!
######################################################
 
CFLAGS = $(shell pkg-config --cflags --libs glib-2.0 gobject-2.0)
ifneq ($(LIBS), )
CFLAGS += $(shell pkg-config --cflags --libs $(LIBS))
endif
ifneq ($(CLIBS), )
CFLAGS += $(shell pkg-config --cflags --libs $(CLIBS))
endif

BUILDFOLDER = .build
VAPIFOLDER = $(BUILDFOLDER)/vapifiles
CFOLDER = $(BUILDFOLDER)/cfiles
OFOLDER = $(BUILDFOLDER)/ofiles

#CFILES = $(patsubst %.vala, %.c, $(SRC))
#OBJ = $(patsubst %.vala, %.o, $(SRC))
#VAPIFILES = $(patsubst %.vala, %.vapi, $(SRC))
	

CFILES = $(addprefix $(CFOLDER)/, $(patsubst %.vala, %.c, $(SRC)))
OBJ = $(addprefix $(OFOLDER)/, $(patsubst %.vala, %.o, $(SRC)))
VAPIFILES= $(addprefix $(VAPIFOLDER)/, $(patsubst %.vala, %.vapi, $(SRC)))


MKDIR_P = mkdir -p




FOLDERS = $(VAPIFOLDER) $(CFOLDER) $(OFOLDER)


info:
	@echo "clean - clean"
	@echo "all   - all"

$(FOLDERS):
	$(MKDIR_P) $(FOLDERS)

clean:
	rm -rf $(BUILDFOLDER)
	rm -f $(TARGET)

$(VAPIFOLDER)/%.vapi: %.vala
	@if [ $(@D) != "." ]; then $(MKDIR_P) $(@D); fi
	valac --fast-vapi=$@ $< && touch $@
#       valac --fast-vapi=$*.vapi $*.vala && touch $*.vapi

$(CFOLDER)/%.c: %.vala  
	@if [ $(@D) != "." ]; then $(MKDIR_P) $(@D); fi  
	valac -C $*.vala $(VFLAGS) $(addprefix --use-fast-vapi=, $(patsubst $(VAPIFOLDER)/$(*).vapi, , $(VAPIFILES))) $(addprefix --pkg , $(VALALIBS)) $(addprefix --pkg , $(LIBS)) && mv $*.c $@ && touch $@

$(OFOLDER)/%.o: $(CFOLDER)/%.c
	@if [ $(@D) != "." ]; then $(MKDIR_P) $(@D); fi
	$(CC) $< -c -o $@ $(CFLAGS) && touch $@

$(TARGET): $(FOLDERS) $(VAPIFILES) $(CFILES) $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(TARGET) && touch $(TARGET)

$(EXTENSION):
	valac $(addprefix --pkg , $(EXT_LIBS)) --vapidir=vapi --library=$@ -X -fPIC -X -shared -o $@.so src/alaia_extension.vala
	rm $(EXTENSION).vapi
	mv $(EXTENSION).so data/alaia/wpe/

all: $(TARGET) $(EXTENSION)

install: $(TARGET)
	mkdir -p /usr/local/share/$(TARGET)
	cp -r data/* /usr/local/share/
	mkdir -p /etc/$(TARGET)
	cp -r cfg/* /etc/$(TARGET)
	cp $(TARGET) /usr/local/bin/

uninstall:
	rm -rf /usr/local/share/$(TARGET)
	find /usr/local/share/icons -name alaia.png | xargs -I{} rm {}
	rm /usr/local/share/applications/alaia.desktop
	rm -rf /etc/$(TARGET)
	rm /usr/local/bin/$(TARGET)
