ERLC = erlc
ERL = erl
SRC = main.erl
BEAM = main.beam

.PHONY: all clean run shell

all: $(BEAM)

$(BEAM): $(SRC)
	$(ERLC) $(SRC)

run: $(BEAM)
	$(ERL) -noshell -s main start -s init stop

shell: $(BEAM)
	$(ERL) -pa . -s main start

clean:
	rm -f *.beam
