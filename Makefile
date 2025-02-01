# Foundry Project Makefile
.PHONY: test coverage clean snapshot report audit help

# Configuration
DAPP_SRC := src
TEST_SRC := test
COVERAGE_DIR := coverage
AUDIT_DIR := audit
COVERAGE_FILTER := "(test/|dependencies/|script/|v2/)"
FILTER_PATHS := "@openzeppelin|@uniswap"

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  test      Run tests with verbose output"
	@echo "  coverage  Show coverage summary"
	@echo "  report    Generate and open coverage report"
	@echo "  audit     Run security analysis"
	@echo "  clean     Remove all build files"
	@echo "  snapshot  Create gas snapshot"

test: clean
	@echo "🧪 Running tests..."
	@forge test -vv

coverage: clean
	@echo "📊 Running coverage analysis..."
	@forge coverage --no-match-coverage $(COVERAGE_FILTER)

report: clean coverage-dirs
	@echo "📈 Generating LCOV report..."
	@forge coverage --no-match-coverage $(COVERAGE_FILTER) --report lcov >/dev/null && mv lcov.info $(COVERAGE_DIR)/lcov.info
	@echo "🖨️  Building HTML report..."
	@genhtml $(COVERAGE_DIR)/lcov.info --output-directory $(COVERAGE_DIR) --ignore-errors inconsistent >/dev/null
	@echo "🚀 Report generated in $(COVERAGE_DIR)/"
	@echo "✅ Opening report..."
	@sleep 1.5
	@open $(COVERAGE_DIR)/index.html || xdg-open $(COVERAGE_DIR)/index.html > /dev/null


audit: audit-dirs
	@echo "🛡️  Running security audit..."
	@aderyn . >  /dev/null 
	@mv report.md $(AUDIT_DIR)/aderyn.md 2>/dev/null
	@slither . --filter-paths $(FILTER_PATHS) --checklist > $(AUDIT_DIR)/slither.md 2>/dev/null || true
	@echo "✅ Audit reports: $(AUDIT_DIR)/"

clean:
	@echo "🧹 Cleaning up..."
	@forge clean
	@forge cache clean
	@rm -rf $(COVERAGE_DIR) $(AUDIT_DIR)

snapshot:
	@echo "📸 Creating snapshot..."
	@forge snapshot

# Directory targets (not PHONY)
coverage-dirs:
	@mkdir -p $(COVERAGE_DIR)

audit-dirs:
	@mkdir -p $(AUDIT_DIR)

.DELETE_ON_ERROR: