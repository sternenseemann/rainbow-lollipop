

# src files. ein find . -name *.vala sollte auch gehen
SRC = src/alaia.vala \

# LIBS werden fuer valac und gcc aufgeloest. VALALIBS und CLIBS
# jeweils nur fuer valac und gcc.
# z.b. valac -pkg libpq  || gcc -lpq
VALALIBS =  
CLIBS = 
LIBS = gtk+-3.0 clutter-1.0 clutter-gtk-1.0 webkitgtk-3.0 gee-1.0

CC = gcc

# Vala compilerflags
VFLAGS = --thread

# programmname.
TARGET = alaia


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
CFILES = $(patsubst %.vala, %.c, $(SRC))
OBJ = $(patsubst %.vala, %.o, $(SRC))
VAPIFILES=$(patsubst %.vala, %.vapi, $(SRC))

info:
	@echo "clean - clean"
	@echo "all   - all"

clean:
	rm -f $(TARGET)
	rm -f `find . -name "*.o"`
	rm -f `find . -name "*.c"`
	rm -f `find . -name "*.vapi"`

%.vapi: %.vala
	valac --fast-vapi=$*.vapi $*.vala && touch $*.vapi

%.c: %.vala 	
	valac -C $*.vala $(VFLAGS) $(addprefix --use-fast-vapi=, $(patsubst $*.vapi, , $(VAPIFILES))) $(addprefix --pkg , $(VALALIBS)) $(addprefix --pkg , $(LIBS)) && touch $*.c

%.o: %.c
	$(CC) $*.c -c -o $*.o $(CFLAGS) && touch $*.o

$(TARGET): $(VAPIFILES) $(CFILES) $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(TARGET) && touch $(TARGET)

all: $(TARGET)



