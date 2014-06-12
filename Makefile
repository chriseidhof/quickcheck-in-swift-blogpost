# To make this project, install the `playground` package: `npm install -g swift-playground-builder`

NAME=quickcheck-in-swift

all: $(NAME).playground.zip

%.playground.zip: %.playground
	zip -r $@ $<

%.playground: %.md
	playground $<

.PHONY: clean

clean:
	rm -r $(NAME).playground*
