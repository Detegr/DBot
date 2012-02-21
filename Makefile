SRC=DBot.d unicafe.d config.d
EXE=dbot

#####################

CC=gdc
LIBS=-lcurl

all: dbot

dbot: $(SRC)
	$(CC) $(SRC) $(LIBS) -o dbot -g3

clean:
	-rm $(EXE)

.PHONY: all clean
