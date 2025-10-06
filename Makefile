# Makefile — v6.43 (SOPS/age helpers)
AGE_DIR := .keys/age
AGE_PRIV := $(AGE_DIR)/age.key
AGE_PUB := $(AGE_DIR)/age.pub
SOPS_FILES := $(shell find secrets env -maxdepth 1 -type f -name '*.env.enc' 2>/dev/null)

.PHONY: help age-keygen sops-setup encrypt decrypt verify print-age-pub
help:
	@echo 'Targets:'; \
	echo '  make sops-setup'; \
	echo '  make age-keygen'; \
	echo '  make encrypt EX=secrets/core.env'; \
	echo '  make decrypt'; \
	echo '  make verify'

$(AGE_DIR):
	mkdir -p $(AGE_DIR)

age-keygen: $(AGE_DIR)
	@if ! command -v age-keygen >/dev/null 2>&1; then echo '>> age missing; run make sops-setup'; exit 1; fi
	age-keygen -o $(AGE_PRIV)
	chmod 600 $(AGE_PRIV)
	grep -m1 '^# public key:' $(AGE_PRIV) | sed 's/# public key: //' > $(AGE_PUB)
	@echo "Public key: $$(cat $(AGE_PUB))"

print-age-pub:
	@cat $(AGE_PUB)

sops-setup:
	sudo apt-get update -y
	sudo apt-get install -y age curl ca-certificates
	@if ! command -v sops >/dev/null 2>&1; then \
		ARCH=$$(dpkg --print-architecture); \
		URL=https://github.com/getsops/sops/releases/latest/download/sops-linux-$$ARCH; \
		curl -fsSL $$URL -o /tmp/sops && chmod +x /tmp/sops && sudo mv /tmp/sops /usr/local/bin/sops; \
	fi
	@echo 'sops: ' $$(sops --version); echo 'age: ' $$(age --version || true)

encrypt:
	@[ -n "$(EX)" ] || (echo 'Set EX=<file> to encrypt'; exit 1)
	@[ -f "$(EX)" ] || (echo 'Missing: $(EX)'; exit 1)
	@[ -f ".sops.yaml" ] || (echo 'Missing .sops.yaml'; exit 1)
	sops --encrypt --in-place --input-type dotenv --output-type dotenv $(EX).enc $(EX)
	@echo 'Encrypted -> $(EX).enc'

decrypt:
	bash scripts/sops-decrypt.sh

verify:
	@for f in $(SOPS_FILES); do echo ">> $$f"; sops -d $$f >/dev/null || exit 1; done; echo OK
