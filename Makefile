SRC=DBot.d unicafe.d config.d wikla.d curl.d
EXE=dbot

#####################

CC=dmd
LIBS=-L-lcurl -L-lssl

all: dbot

dbot: $(SRC)
	$(CC) $(SRC) $(LIBS) -ofdbot -gc

clean:
	-rm $(EXE)

.PHONY: all clean
