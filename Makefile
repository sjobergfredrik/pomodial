SDK ?= $(HOME)/Developer/PlaydateSDK
GAME := Pomodial

# The Roobert fonts ship with the Playdate SDK and aren't redistributable,
# so they're copied in from the local SDK instead of living in the repo.
SDK_FONTS := $(SDK)/Resources/Fonts/Roobert
FONTS := source/fonts/Roobert-24-Medium.fnt source/fonts/Roobert-24-Medium-table-36-36.png \
	source/fonts/Roobert-10-Bold.fnt source/fonts/Roobert-10-Bold-table-12-14.png

.PHONY: build run clean

build: $(FONTS)
	"$(SDK)/bin/pdc" source $(GAME).pdx

run: build
	open -a "$(SDK)/bin/Playdate Simulator.app" $(GAME).pdx

source/fonts/%: $(SDK_FONTS)/%
	@mkdir -p source/fonts
	cp "$<" "$@"

clean:
	rm -rf $(GAME).pdx source/fonts
