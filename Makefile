VERSION=0.5.1
BUILD_DATE=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_HASH=$(shell git rev-parse HEAD)
TARGETS=linux.amd64 linux.arm64 linux.mips64 windows.amd64.exe darwin.amd64 darwin.arm64

LDFLAGS=-ldflags "-X main.versionString=$(VERSION) -X main.buildDate=$(BUILD_DATE) -X main.gitHash=$(GIT_HASH)"
BINARIES=$(foreach r,$(TARGETS),bin/durl-$(VERSION).$(r))
RELEASES=$(subst windows.amd64.tar.gz,windows.amd64.zip,$(foreach r,$(subst .exe,,$(TARGETS)),releases/durl-$(VERSION).$(r).tar.gz))

toc:
	@echo "list of targets:"
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | \
		awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | \
		sort | \
		egrep -v -e '^[^[:alnum:]]' -e '^$@$$' | \
		awk '{ print " ", $$1 }'

binaries: $(BINARIES)
releases: $(RELEASES)
	make $(RELEASES)

clean:
	rm -f $(BINARIES) $(RELEASES)

durl: bin/durl
bin/durl:
	go build $(LDFLAGS) -o $@ .


bin/durl-$(VERSION).%:
	env GOARCH=$(subst .,,$(suffix $(subst .exe,,$@))) GOOS=$(subst .,,$(suffix $(basename $(subst .exe,,$@)))) CGO_ENABLED=0 \
	go build $(LDFLAGS) -o $@ .

releases/durl-$(VERSION).%.zip: bin/durl-$(VERSION).%.exe
	mkdir -p releases
	zip -9 -j -r $@ README.md LICENSE $<
releases/durl-$(VERSION).%.tar.gz: bin/durl-$(VERSION).%
	mkdir -p releases
	tar -cf $(basename $@) README.md LICENSE && \
		tar -rf $(basename $@) --strip-components 1 $< && \
		gzip -9 $(basename $@)


deps-vendor:
	go mod vendor
deps-cleanup:
	go mod tidy


report: report-cyclo report-lint report-staticcheck report-mispell report-ineffassign report-vet
report-cyclo:
	@echo '####################################################################'
	gocyclo .
report-mispell:
	@echo '####################################################################'
	misspell .
report-lint:
	@echo '####################################################################'
	golint ./...
report-ineffassign:
	@echo '####################################################################'
	ineffassign ./... 
report-vet:
	@echo '####################################################################'
	go vet ./...
report-staticcheck:
	@echo '####################################################################'
	staticcheck ./...

fetch-report-tools:
	go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
	go install github.com/client9/misspell/cmd/misspell@latest
	go install github.com/gordonklaus/ineffassign@latest
	go install honnef.co/go/tools/cmd/staticcheck@latest
	go install golang.org/x/lint/golint@latest
 

.PHONY: durl bin/durl
