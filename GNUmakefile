.SUFFIXES:

# commands
LUAC := luac
LUACHECK := luacheck
ZIP := zip -r
# note not povray for windows, as that has different behaviour.
POVRAY := povray
POVRAY_OPTIONS := 
GIT := git

# directories
FACTORIO_MODS := ~/.Factorio/mods

# override the above with local values in the optional local.mk
-include local.mk
# read and cache PACKAGE_NAME/VERSION
-include info.mk

OUTPUT_NAME := $(PACKAGE_NAME)_$(VERSION_STRING)

OUTPUT_DIR := build/$(OUTPUT_NAME)

COPY_FILES := $(wildcard *.png **/*.png)
COPY_FILES += $(wildcard locale/**/*.cfg)

SED_FILES += $(wildcard *.md **/*.md)
SED_FILES += $(wildcard *.txt **/*.txt)
SED_FILES += $(wildcard *.json **/*.json)

LUA_FILES := $(wildcard *.lua **/*.lua)

POV_FILES := $(wildcard *.pov **/*.pov)
PNG_FILES := $(shell ./find-required-images.pl $(LUA_FILES))

TARGET_FILES := $(addprefix $(OUTPUT_DIR)/,$(COPY_FILES))
TARGET_FILES += $(addprefix $(OUTPUT_DIR)/,$(SED_FILES))
TARGET_FILES += $(addprefix $(OUTPUT_DIR)/,$(LUA_FILES))
TARGET_FILES += $(addprefix $(OUTPUT_DIR)/,$(PNG_FILES))

TARGET_DIRS := $(sort $(dir $(TARGET_FILES)))

SED_EXPRS := -e 's/{{MOD_NAME}}/$(PACKAGE_NAME)/g'
SED_EXPRS += -e 's/{{VERSION}}/$(VERSION_STRING)/g'

.PHONY: all
all: verify package install

.PHONY: release
release: verify package install tag

.PHONY: directories
directories: | $(TARGET_DIRS)

$(TARGET_DIRS):
	mkdir -p $@

.PHONY: package-copy
package-copy: directories $(TARGET_FILES)
	echo $(LUA_FILES)

.PHONY: package
package: package-copy
	cd build && $(ZIP) $(OUTPUT_NAME).zip $(OUTPUT_NAME)

.PHONY: clean
clean:
	rm -f info.mk imagedep.mk
	rm -rf build/

.PHONY: verify
verify:
	$(LUACHECK) $(LUA_FILES)

.PHONY: install
install: package-copy
	if [ -d $(FACTORIO_MODS) ]; then \
		rm -rf $(FACTORIO_MODS)/$(OUTPUT_NAME) ; \
		cp -R build/$(OUTPUT_NAME) $(FACTORIO_MODS) ; \
	fi;

.PHONY: tag
tag:
	$(git) tag -f $(VERSION_STRING)

$(OUTPUT_DIR)/%.png: %.png
	cp $< $@

$(OUTPUT_DIR)/%.cfg: %.cfg
	cp $< $@

$(OUTPUT_DIR)/%.md: %.md info.mk
	sed $(SED_EXPRS) $< > $@

$(OUTPUT_DIR)/%.txt: %.txt info.mk
	sed $(SED_EXPRS) $< > $@

$(OUTPUT_DIR)/%.json: %.json info.mk
	sed $(SED_EXPRS) $< > $@

$(OUTPUT_DIR)/%.lua: %.lua info.mk
	sed $(SED_EXPRS) $< > $@
	$(LUAC) -p $@

$(OUTPUT_DIR)/graphics/icons/%.png: graphics/%.pov povray.ini render_icon.sh
	./render_icon.sh $< $@ icon $(POVRAY_OPTIONS)

$(OUTPUT_DIR)/graphics/entity/%.png: graphics/%.pov povray.ini render_icon.sh
	./render_icon.sh $< $@ entity $(POVRAY_OPTIONS)

$(OUTPUT_DIR)/graphics/technology/%.png: graphics/%.pov povray.ini render_icon.sh
	./render_icon.sh $< $@ technology $(POVRAY_OPTIONS)

info.mk: info.json
	echo "PACKAGE_NAME := $$(jq -r .name < $<)\nVERSION_STRING := $$(jq -r .version < $<)" > $@

imagedep.mk: read-image-deps.pl
	./read-image-deps.pl $(PNG_FILES) > $@

-include imagedep.mk
