.PHONY: deps-help
deps-help: ## Show available dependency reporting commands
	@echo "📋 Available dependency reporting commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "🔑 GitHub API Integration:"
	@if [ -n "$$GITHUB_CREDENTIALS" ]; then \
		echo "  ✅ GitHub token detected - Enhanced API limits (5000 req/hour)"; \
	else \
		echo "  ⚠️  No GitHub token - Limited API access (60 req/hour)"; \
		echo "  💡 Set GITHUB_CREDENTIALS environment variable for better performance"; \
	fi

.PHONY: install-tools
install-tools: ## Install all required tools for dependency reporting
	@echo "🔧 Installing required tools for dependency reporting..."
	@echo ""

	@echo "📦 Installing Go tools..."
	@echo "Installing govulncheck..."
	@go install golang.org/x/vuln/cmd/govulncheck@latest
	@echo ""

	@echo "🔍 Checking system tools..."
	@if command -v jq >/dev/null 2>&1; then \
		echo "✅ jq is already installed"; \
	else \
		echo "❌ jq is not installed"; \
		echo "   Install with: brew install jq (macOS) or apt-get install jq (Ubuntu)"; \
	fi

	@if command -v curl >/dev/null 2>&1; then \
		echo "✅ curl is already installed"; \
	else \
		echo "❌ curl is not installed"; \
		echo "   Install with: brew install curl (macOS) or apt-get install curl (Ubuntu)"; \
	fi

	@if command -v date >/dev/null 2>&1; then \
		echo "✅ date is already installed (system tool)"; \
	else \
		echo "❌ date is not installed (should be available on all Unix systems)"; \
	fi

	@echo ""
	@echo "🎉 Tool installation completed!"
	@echo ""
	@echo "📋 Installed Go tools:"
	@echo "   - govulncheck: $$(which govulncheck 2>/dev/null || echo 'not found in PATH')"
	@echo ""
	@echo "💡 If Go tools are not found in PATH, make sure GOPATH/bin is in your PATH:"
	@echo "   export PATH=\$$PATH:\$$(go env GOPATH)/bin"

.PHONY: check-github-api
check-github-api: ## Test GitHub API connection and rate limits
	@echo "🔍 Testing GitHub API connection..."
	@echo ""
	@if [ -n "$$GITHUB_CREDENTIALS" ]; then \
		echo "🔑 Using GitHub token from GITHUB_CREDENTIALS"; \
		rate_data=$$(curl -s -H "Authorization: token $$GITHUB_CREDENTIALS" -H "Accept: application/vnd.github.v3+json" https://api.github.com/rate_limit 2>/dev/null); \
		if echo "$$rate_data" | jq -e '.rate' >/dev/null 2>&1; then \
			limit=$$(echo "$$rate_data" | jq -r '.rate.limit'); \
			remaining=$$(echo "$$rate_data" | jq -r '.rate.remaining'); \
			reset_time=$$(echo "$$rate_data" | jq -r '.rate.reset'); \
			reset_date=$$(date -r $$reset_time 2>/dev/null || date -d "@$$reset_time" 2>/dev/null || echo "unknown"); \
			echo "✅ API Connection: Success"; \
			echo "📊 Rate Limit: $$remaining/$$limit requests remaining"; \
			echo "🔄 Reset Time: $$reset_date"; \
		else \
			echo "❌ API Connection: Failed"; \
			echo "$$rate_data"; \
		fi; \
	else \
		echo "⚠️  No GitHub token found in GITHUB_CREDENTIALS"; \
		echo "🔍 Testing unauthenticated API (60 requests/hour limit)..."; \
		test_data=$$(curl -s --max-time 5 https://api.github.com/zen 2>/dev/null); \
		if [ -n "$$test_data" ]; then \
			echo "✅ Unauthenticated API: Working"; \
			echo "💡 Set GITHUB_CREDENTIALS for higher rate limits (5000 requests/hour)"; \
		else \
			echo "❌ API Connection: Failed"; \
		fi; \
	fi

.PHONY: vuln-check
vuln-check: check-tools ## Run vulnerability scan on the codebase (auto-generates code if needed)
	@echo "🔍 Running vulnerability scan..."
	@echo ""
	@if go build ./... >/dev/null 2>&1; then \
		echo "✅ Code compilation successful, running vulnerability scan..."; \
		govulncheck ./...; \
	else \
		echo "⚠️  Code compilation failed, running code generation..."; \
		$(MAKE) -f $(MAKEFILE_LIST) gen; \
		echo "🔄 Retrying compilation after code generation..."; \
		if go build ./... >/dev/null 2>&1; then \
			echo "✅ Code compilation successful after generation, running vulnerability scan..."; \
			govulncheck ./...; \
		else \
			echo "❌ Code compilation still failed after generation."; \
			echo ""; \
			echo "Compilation errors:"; \
			go build ./...; \
			exit 1; \
		fi; \
	fi

.PHONY: check-tools
check-tools: ## Check if all required tools are installed
	@echo "🔍 Checking required tools for dependency reporting..."
	@echo ""
	@tools_missing=0; \
	if command -v govulncheck >/dev/null 2>&1; then \
		echo "✅ govulncheck: $$(govulncheck -version 2>/dev/null || echo 'installed')"; \
	else \
		echo "❌ govulncheck: not found"; \
		tools_missing=1; \
	fi; \
	if command -v jq >/dev/null 2>&1; then \
		echo "✅ jq: $$(jq --version)"; \
	else \
		echo "❌ jq: not found"; \
		tools_missing=1; \
	fi; \
	if command -v curl >/dev/null 2>&1; then \
		echo "✅ curl: $$(curl --version | head -1)"; \
	else \
		echo "❌ curl: not found"; \
		tools_missing=1; \
	fi; \
	if command -v date >/dev/null 2>&1; then \
		echo "✅ date: system tool available"; \
	else \
		echo "❌ date: not found (system issue)"; \
		tools_missing=1; \
	fi; \
	echo ""; \
	if [ -n "$$GITHUB_CREDENTIALS" ]; then \
		echo "🔑 GitHub token: available (enhanced API limits)"; \
		rate_info=$$(curl -s -H "Authorization: token $$GITHUB_CREDENTIALS" -H "Accept: application/vnd.github.v3+json" https://api.github.com/rate_limit 2>/dev/null | jq -r '.rate.remaining // "unknown"' 2>/dev/null || echo "unknown"); \
		if [ "$$rate_info" != "unknown" ] && [ "$$rate_info" -gt 0 ]; then \
			echo "   API requests remaining: $$rate_info"; \
		fi; \
	else \
		echo "⚠️  GitHub token: not found (limited to 60 requests/hour)"; \
		echo "   Set GITHUB_CREDENTIALS environment variable for higher limits"; \
	fi; \
	echo ""; \
	if [ $$tools_missing -eq 0 ]; then \
		echo "🎉 All required tools are installed!"; \
	else \
		echo "⚠️  Some tools are missing. Run 'make install-tools' to install them."; \
		exit 1; \
	fi

.PHONY: deps-report
deps-report: check-tools ## Generate dependency report with GitHub API integration (auto-generates code if needed)
	@echo "📊 Generating dependency report..."
	@echo "# Dependency Security & License Report" > deps-report.md
	@echo "Generated: $(shell date)" >> deps-report.md
	@echo "" >> deps-report.md

	@echo "## 🔍 Vulnerability Scan Results" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "_Scanning for known security vulnerabilities in dependencies..._" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "Running vulnerability scan..." >&2
	@if go build ./... >/dev/null 2>&1; then \
		echo "✅ Code compilation successful, running vulnerability scan..." >&2; \
		$(MAKE) -f $(MAKEFILE_LIST) _run-vuln-scan-first; \
	else \
		echo "⚠️  Code compilation failed, running code generation..." >&2; \
		$(MAKE) -f $(MAKEFILE_LIST) gen >/dev/null 2>&1; \
		echo "🔄 Retrying vulnerability scan after code generation..." >&2; \
		if go build ./... >/dev/null 2>&1; then \
			echo "✅ Code compilation successful after generation, running vulnerability scan..." >&2; \
			$(MAKE) -f $(MAKEFILE_LIST) _run-vuln-scan-first; \
		else \
			echo "❌ **Compilation Failed** - Vulnerability scan could not be completed." >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo "<details>" >> deps-report.md; \
			echo "<summary>🔍 Click to view compilation errors</summary>" >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo '```' >> deps-report.md; \
			go build ./... >> deps-report.md 2>&1 || true; \
			echo '```' >> deps-report.md; \
			echo "</details>" >> deps-report.md; \
		fi; \
	fi

	@echo "" >> deps-report.md
	@echo "## 📦 Direct Dependencies" >> deps-report.md
	@echo "" >> deps-report.md

	@echo "Collecting dependency information..." >&2
	@direct_deps=$$(go list -m -json all | jq -r 'select(.Main != true) | select(.Indirect != true) | .Path' | wc -l | tr -d ' '); \
	if [ "$$direct_deps" -eq 0 ]; then \
		echo "✅ No direct dependencies found." >&2; \
		echo "✅ **No Direct Dependencies Found**" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "This project currently has no direct external dependencies. This is excellent for:" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "- **🔒 Security**: Reduced attack surface with no third-party code" >> deps-report.md; \
		echo "- **🚀 Performance**: No external dependency overhead" >> deps-report.md; \
		echo "- **📦 Simplicity**: Easier deployment and distribution" >> deps-report.md; \
		echo "- **🔧 Maintenance**: No dependency updates or compatibility issues" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Note:** This analysis only covers direct dependencies. The project may still use Go standard library packages." >> deps-report.md; \
	else \
		echo "Found $$direct_deps direct dependencies." >&2; \
		echo "| Package | Description | Current | Latest | Version Date | License | Maintenance |" >> deps-report.md; \
		echo "|---------|-------------|---------|--------|--------------|---------|-------------|" >> deps-report.md; \
		go list -m -json all | jq -r 'select(.Main != true) | select(.Indirect != true) | .Path' | while read -r dep; do \
		echo "Processing $$dep..." >&2; \
		dep_info=$$(go list -m -json $$dep 2>/dev/null); \
		current=$$(echo "$$dep_info" | jq -r '.Version // "unknown"'); \
		version_time=$$(echo "$$dep_info" | jq -r '.Time // "unknown"' | cut -d'T' -f1); \
		replace_info=$$(echo "$$dep_info" | jq -r '.Replace.Path // ""'); \
		latest_info=$$(go list -u -m -json $$dep 2>/dev/null); \
		latest=$$(echo "$$latest_info" | jq -r '.Update.Version // "current"'); \
		license_name=$$($(MAKE) _detect-license DEP=$$dep 2>/dev/null || echo "Not detected"); \
		case "$$license_name" in \
			*GPL*|*AGPL*|*LGPL*) \
				license_display="$$license_name (⚠️ Copyleft)"; \
				;; \
			*Commercial*|*Proprietary*) \
				license_display="$$license_name (⚠️ Commercial)"; \
				;; \
			*CC-BY-NC*|*NonCommercial*) \
				license_display="$$license_name (⚠️ Non-Commercial)"; \
				;; \
			MIT|Apache*|BSD*|ISC|Unlicense) \
				license_display="$$license_name (✅ Permissive)"; \
				;; \
			MPL*|EPL*|CDDL*) \
				license_display="$$license_name (⚠️ Weak Copyleft)"; \
				;; \
			"Not detected") \
				license_display="❓ Not detected"; \
				;; \
			*) \
				license_display="$$license_name (❓ Review needed)"; \
				;; \
		esac; \
		if [ -n "$$replace_info" ]; then \
			update_status="🔧 custom fork"; \
		elif [ "$$latest" != "current" ] && [ "$$latest" != "unknown" ] && [ -n "$$latest" ]; then \
			update_status="⚠️ $$latest"; \
		else \
			update_status="✅ current"; \
		fi; \
		case "$$dep" in \
			github.com/*) \
				package_name=$$(echo "$$dep" | sed 's|github.com/||'); \
				package_link="[$$package_name](https://$$dep)"; \
				;; \
			gitlab.com/*) \
				package_name=$$(echo "$$dep" | sed 's|gitlab.com/||'); \
				package_link="[$$package_name](https://$$dep)"; \
				;; \
			bitbucket.org/*) \
				package_name=$$(echo "$$dep" | sed 's|bitbucket.org/||'); \
				package_link="[$$package_name](https://$$dep)"; \
				;; \
			golang.org/x/*) \
				package_name=$$(echo "$$dep" | sed 's|golang.org/x/||'); \
				repo_url=$$(echo "$$dep" | sed 's|golang.org/x/|https://github.com/golang/|'); \
				package_link="[golang/$$package_name]($$repo_url)"; \
				;; \
			google.golang.org/grpc*) \
				package_link="[grpc/grpc-go](https://github.com/grpc/grpc-go)"; \
				;; \
			google.golang.org/protobuf*) \
				package_link="[protocolbuffers/protobuf-go](https://github.com/protocolbuffers/protobuf-go)"; \
				;; \
			go.uber.org/*) \
				package_name=$$(echo "$$dep" | sed 's|go.uber.org/||'); \
				repo_url=$$(echo "$$dep" | sed 's|go.uber.org/|https://github.com/uber-go/|'); \
				package_link="[uber-go/$$package_name]($$repo_url)"; \
				;; \
			gopkg.in/*) \
				if echo "$$dep" | grep -q '/'; then \
					repo_path=$$(echo "$$dep" | sed 's|gopkg.in/||' | sed 's|\.v[0-9]*||'); \
					package_link="[$$repo_path](https://github.com/$$repo_path)"; \
				else \
					package_name=$$(echo "$$dep" | sed 's|gopkg.in/||' | sed 's|\.v[0-9]*||'); \
					package_link="[go-$$package_name/$$package_name](https://github.com/go-$$package_name/$$package_name)"; \
				fi; \
				;; \
			*) \
				package_link="$$dep"; \
				;; \
		esac; \
		if [ "$$version_time" != "unknown" ] && [ -n "$$version_time" ]; then \
			if date -d "$$version_time" >/dev/null 2>&1; then \
				version_epoch=$$(date -d "$$version_time" +%s 2>/dev/null); \
				current_epoch=$$(date +%s); \
				days_ago=$$(( (current_epoch - version_epoch) / 86400 )); \
			elif date -j -f "%Y-%m-%d" "$$version_time" >/dev/null 2>&1; then \
				version_epoch=$$(date -j -f "%Y-%m-%d" "$$version_time" +%s 2>/dev/null); \
				current_epoch=$$(date +%s); \
				days_ago=$$(( (current_epoch - version_epoch) / 86400 )); \
			else \
				days_ago=999; \
			fi; \
			if [ "$$days_ago" -le 90 ]; then \
				time_display="🟢 $$version_time"; \
			elif [ "$$days_ago" -le 180 ]; then \
				time_display="🟡 $$version_time"; \
			elif [ "$$days_ago" -le 365 ]; then \
				time_display="🟠 $$version_time"; \
			else \
				time_display="🔴 $$version_time"; \
			fi; \
		else \
			time_display="❓ Unknown"; \
		fi; \
		maintenance_info=$$($(MAKE) _get-maintenance-info DEP=$$dep 2>/dev/null || echo "❓ Unknown"); \
		maintenance_status="$$maintenance_info"; \
		anchor_id=$$(echo "$$dep" | sed 's|github.com/||' | sed 's|[^a-zA-Z0-9]|-|g' | tr '[:upper:]' '[:lower:]'); \
		description_link="[📝 Edit](#$$anchor_id)"; \
		echo "| $$package_link | $$description_link | \`$$current\` | $$update_status | $$time_display | $$license_display | $$maintenance_status |" >> deps-report.md; \
	done; \
	fi

	@echo "" >> deps-report.md
	@echo "## 📝 Package Descriptions" >> deps-report.md
	@echo "" >> deps-report.md

	@direct_deps=$$(go list -m -json all | jq -r 'select(.Main != true) | select(.Indirect != true) | .Path' | wc -l | tr -d ' '); \
	if [ "$$direct_deps" -eq 0 ]; then \
		echo "No direct dependencies to describe. This section will be populated when external packages are added to the project." >> deps-report.md; \
	else \
		echo "_Edit this section to add descriptions for each dependency. This helps team members understand why each package is used and how it fits into the project._" >> deps-report.md; \
		echo "" >> deps-report.md; \
		go list -m -json all | jq -r 'select(.Main != true) | select(.Indirect != true) | .Path' | while read -r dep; do \
		anchor_id=$$(echo "$$dep" | sed 's|github.com/||' | sed 's|[^a-zA-Z0-9]|-|g' | tr '[:upper:]' '[:lower:]'); \
		package_name=$$(echo "$$dep" | sed 's|.*/||'); \
		echo "### $$anchor_id" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Package:** \`$$dep\`" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Purpose:** _[Add description here - What does this package do? Why is it used?]_" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Usage:** _[Add usage details - How is it used in the project?]_" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Notes:** _[Add any important notes, alternatives, or migration plans]_" >> deps-report.md; \
		echo "" >> deps-report.md; \
	done; \
	fi

	@echo "" >> deps-report.md

	@echo "## 🌐 Third-Party API Integrations" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "_This section documents external APIs and services that the application integrates with. Regular review helps ensure security, compliance, and maintenance of these integrations._" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "---" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "### google-maps-api" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Service:** Google Maps Platform API" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Endpoint:** \`https://maps.googleapis.com/maps/api/geocode/json\`" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Purpose:** _[Add description - Geocoding addresses to coordinates for location services]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Authentication:** _[API Key / OAuth / Basic Auth]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Rate Limits:** _[1000 requests/day, 50 requests/second]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Data Sensitivity:** _[PII/Location data - describe what data is sent]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Error Handling:** _[Timeout: 5s, Retry: 3x with exponential backoff]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Monitoring:** _[Metrics tracked, alerts configured]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Security:** _[SSL/TLS encryption, certificate validation, credential storage]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Last Reviewed:** _[Date - when was this integration last audited]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Notes:** _[Migration plans, known issues, alternatives considered]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "---" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "### Template for New Integration" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Service:** _[Service Name and Provider]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Endpoint:** _[Primary API endpoint URL]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Purpose:** _[What does this integration do? Why do we need it?]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Authentication:** _[How do we authenticate? API key, OAuth, etc.]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Rate Limits:** _[What are the usage limits? How do we handle them?]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Data Sensitivity:** _[What data do we send? Any PII or sensitive information?]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Error Handling:** _[How do we handle failures? Timeouts, retries, fallbacks?]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Monitoring:** _[What metrics do we track? What alerts are configured?]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Security:** _[SSL/TLS, certificate validation, credential storage, encryption]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Last Reviewed:** _[When was this integration last reviewed for security/compliance?]_" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "**Notes:** _[Any important notes, compliance requirements, or future plans?]_" >> deps-report.md
	@echo "" >> deps-report.md

	@echo "## 📋 License Categories" >> deps-report.md
	@echo "- ✅ **Permissive**: MIT, Apache-2.0, BSD, ISC, Unlicense - Generally safe for commercial use" >> deps-report.md
	@echo "- ⚠️ **Weak Copyleft**: MPL-2.0, EPL, CDDL - May require source disclosure for modifications" >> deps-report.md
	@echo "- ⚠️ **Copyleft**: GPL, AGPL, LGPL - Strong copyleft requirements" >> deps-report.md
	@echo "- ⚠️ **Commercial/Proprietary**: Requires commercial licensing" >> deps-report.md
	@echo "- ⚠️ **Non-Commercial**: Restricted to non-commercial use only" >> deps-report.md
	@echo "- ❓ **Not detected**: License could not be automatically detected - manual review required" >> deps-report.md
	@echo "- ❓ **Review needed**: Unusual license requiring manual review" >> deps-report.md

	@echo "" >> deps-report.md
	@echo "## 📊 Update Status Legend" >> deps-report.md
	@echo "- ✅ **Current**: Using the latest available version" >> deps-report.md
	@echo "- ⚠️ **Update Available**: Newer version available (shows version number)" >> deps-report.md
	@echo "- 🔧 **Custom Fork**: Using a custom fork or replace directive - **requires manual review**" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "## 📊 Version Date Legend" >> deps-report.md
	@echo "- 🟢 **Recent**: Version released within 3 months" >> deps-report.md
	@echo "- 🟡 **Moderate**: Version released within 6 months" >> deps-report.md
	@echo "- 🟠 **Old**: Version released within 1 year" >> deps-report.md
	@echo "- 🔴 **Very Old**: Version released over 1 year ago" >> deps-report.md
	@echo "- ❓ **Unknown**: Could not determine version date" >> deps-report.md

	@echo "" >> deps-report.md
	@echo "## 🔧 Maintenance Status Legend" >> deps-report.md
	@echo "- 🟢 **Active/Recent**: Last commit or version within 3 months" >> deps-report.md
	@echo "- 🟡 **Moderate**: Last commit or version within 6 months" >> deps-report.md
	@echo "- 🟠 **Slow/Old**: Last commit or version within 1 year" >> deps-report.md
	@echo "- 🔴 **Stale/Very Old**: Last commit or version over 1 year ago" >> deps-report.md
	@echo "- ⏱️ **Rate limited**: GitHub API rate limit exceeded" >> deps-report.md
	@echo "- ❓ **Unknown**: Could not determine maintenance status" >> deps-report.md
	@echo "" >> deps-report.md
	@echo "## 🔑 GitHub API Integration" >> deps-report.md
	@if [ -n "$$GITHUB_CREDENTIALS" ]; then \
		echo "- ✅ **Enhanced Mode**: Using authenticated GitHub API (5000 requests/hour)" >> deps-report.md; \
	else \
		echo "- ⚠️ **Limited Mode**: Using unauthenticated GitHub API (60 requests/hour)" >> deps-report.md; \
		echo "- 💡 **Tip**: Set GITHUB_CREDENTIALS environment variable for better performance" >> deps-report.md; \
	fi
	@echo "" >> deps-report.md

	@echo "✅ Dependency report generated: deps-report.md"

# Detect license from GitHub repository API
.PHONY: _detect-license
_detect-license:
	@if [ -z "$(DEP)" ]; then echo "Not detected"; exit 0; fi
	@case "$(DEP)" in \
		github.com/*) \
			repo_path=$$(echo "$(DEP)" | sed 's|github.com/||' | sed 's|/v[0-9].*||'); \
			api_url="https://api.github.com/repos/$$repo_path"; \
			if [ -n "$$GITHUB_CREDENTIALS" ]; then \
				repo_data=$$(curl -s --max-time 5 -H "Authorization: token $$GITHUB_CREDENTIALS" -H "Accept: application/vnd.github.v3+json" "$$api_url" 2>/dev/null); \
			else \
				repo_data=$$(curl -s --max-time 2 "$$api_url" 2>/dev/null); \
			fi; \
			if echo "$$repo_data" | jq -e '.license.spdx_id' >/dev/null 2>&1; then \
				license_id=$$(echo "$$repo_data" | jq -r '.license.spdx_id'); \
				if [ "$$license_id" != "null" ] && [ "$$license_id" != "NOASSERTION" ]; then \
					echo "$$license_id"; \
				else \
					license_name=$$(echo "$$repo_data" | jq -r '.license.name // "Not detected"'); \
					if [ "$$license_name" != "Not detected" ] && [ "$$license_name" != "null" ]; then \
						echo "$$license_name"; \
					else \
						echo "Not detected"; \
					fi; \
				fi; \
			else \
				echo "Not detected"; \
			fi ;; \
		*) \
			echo "Not detected"; \
	esac

# Run vulnerability scan with formatted output (for first position in report)
.PHONY: _run-vuln-scan-first
_run-vuln-scan-first:
	@echo "Running vulnerability scan..." >&2
	@govulncheck ./... > /tmp/vuln_raw.txt 2>&1 || true; \
	if [ ! -s /tmp/vuln_raw.txt ]; then \
		echo "### ❌ Vulnerability Scanner Not Available" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "The \`govulncheck\` tool is not installed or not working properly." >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Installation:** \`go install golang.org/x/vuln/cmd/govulncheck@latest\`" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Alternative:** Run \`make install-tools\` to install required tools." >> deps-report.md; \
	elif grep -q "No vulnerabilities found" /tmp/vuln_raw.txt; then \
		echo "### ✅ No Vulnerabilities Found" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "🎉 **Great news!** No known security vulnerabilities were detected in your dependencies." >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Scan Status:** ✅ Complete" >> deps-report.md; \
		echo "**Vulnerabilities Found:** 0" >> deps-report.md; \
		echo "**Action Required:** None - Keep dependencies updated" >> deps-report.md; \
	elif grep -q "Your code is affected by" /tmp/vuln_raw.txt; then \
		vuln_count=$$(grep -o "affected by [0-9]* vulnerabilities" /tmp/vuln_raw.txt | grep -o "[0-9]*" | head -1); \
		echo "### 🚨 CRITICAL: Security Vulnerabilities Detected ($$vuln_count found)" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**⚠️ IMMEDIATE ACTION REQUIRED:** Your code is directly affected by $$vuln_count vulnerabilities." >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "| # | Vulnerability ID | Description | Found In | Fixed In | Status |" >> deps-report.md; \
		echo "|---|------------------|-------------|----------|----------|--------|" >> deps-report.md; \
		counter=1; \
		grep -n "Vulnerability #" /tmp/vuln_raw.txt | while IFS=':' read -r line_num vuln_header; do \
			vuln_id=$$(echo "$$vuln_header" | sed 's/Vulnerability #[0-9]*: //'); \
			desc_line=$$(sed -n "$$((line_num + 1))p" /tmp/vuln_raw.txt); \
			url_line=$$(sed -n "$$((line_num + 2))p" /tmp/vuln_raw.txt); \
			source_line=$$(sed -n "$$((line_num + 3))p" /tmp/vuln_raw.txt); \
			found_line=$$(sed -n "$$((line_num + 4))p" /tmp/vuln_raw.txt); \
			fixed_line=$$(sed -n "$$((line_num + 5))p" /tmp/vuln_raw.txt); \
			desc_short=$$(echo "$$desc_line" | head -c 45)...; \
			url=$$(echo "$$url_line" | grep -o "https://[^[:space:]]*" || echo ""); \
			found_in=$$(echo "$$found_line" | sed 's/.*Found in: //' || echo "Unknown"); \
			fixed_in=$$(echo "$$fixed_line" | sed 's/.*Fixed in: //' || echo "See advisory"); \
			if [ -n "$$url" ]; then \
				vuln_link="[$$vuln_id]($$url)"; \
			else \
				vuln_link="$$vuln_id"; \
			fi; \
			echo "| $$counter | $$vuln_link | $$desc_short | \`$$found_in\` | \`$$fixed_in\` | 🚨 **UPDATE NOW** |" >> deps-report.md; \
			counter=$$((counter + 1)); \
		done; \
		echo "" >> deps-report.md; \
		echo "#### 🛠️ Immediate Actions Required" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "1. **🔴 HIGH PRIORITY**: Update Go to the latest version to fix standard library vulnerabilities" >> deps-report.md; \
		echo "2. **📋 Security Review**: Check the example traces below to see if your code uses vulnerable paths" >> deps-report.md; \
		echo "3. **🔧 Update Dependencies**: Run \`go mod tidy && go get -u\` for affected packages" >> deps-report.md; \
		echo "4. **✅ Re-scan**: Run \`make vuln-check\` after updates to verify fixes" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "#### 📋 Vulnerability Details & Example Traces" >> deps-report.md; \
		echo "" >> deps-report.md; \
		counter=1; \
		grep -n "Vulnerability #" /tmp/vuln_raw.txt | while IFS=':' read -r line_num vuln_header; do \
			vuln_id=$$(echo "$$vuln_header" | sed 's/Vulnerability #[0-9]*: //'); \
			desc_line=$$(sed -n "$$((line_num + 1))p" /tmp/vuln_raw.txt); \
			url_line=$$(sed -n "$$((line_num + 2))p" /tmp/vuln_raw.txt); \
			source_line=$$(sed -n "$$((line_num + 3))p" /tmp/vuln_raw.txt); \
			found_line=$$(sed -n "$$((line_num + 4))p" /tmp/vuln_raw.txt); \
			fixed_line=$$(sed -n "$$((line_num + 5))p" /tmp/vuln_raw.txt); \
			url=$$(echo "$$url_line" | grep -o "https://[^[:space:]]*" || echo ""); \
			found_in=$$(echo "$$found_line" | sed 's/.*Found in: //' || echo "Unknown"); \
			fixed_in=$$(echo "$$fixed_line" | sed 's/.*Fixed in: //' || echo "See advisory"); \
			echo "<details>" >> deps-report.md; \
			echo "<summary><strong>$$counter. $$vuln_id</strong> - Click to view details</summary>" >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo "**Description:** $$desc_line" >> deps-report.md; \
			echo "" >> deps-report.md; \
			if [ -n "$$url" ]; then \
				echo "**More Information:** [$$url]($$url)" >> deps-report.md; \
				echo "" >> deps-report.md; \
			fi; \
			echo "**Source:** $$source_line" >> deps-report.md; \
			echo "**Found in:** \`$$found_in\`" >> deps-report.md; \
			echo "**Fixed in:** \`$$fixed_in\`" >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo "**Example traces in your code:**" >> deps-report.md; \
			echo '```' >> deps-report.md; \
			sed -n "$$((line_num + 6)),/^$$/p" /tmp/vuln_raw.txt | head -20 >> deps-report.md; \
			echo '```' >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo "</details>" >> deps-report.md; \
			echo "" >> deps-report.md; \
			counter=$$((counter + 1)); \
		done; \
	else \
		echo "### ✅ Vulnerability Scan Completed" >> deps-report.md; \
		echo "" >> deps-report.md; \
		if grep -q "vulnerabilities in modules you require" /tmp/vuln_raw.txt; then \
			indirect_count=$$(grep -o "[0-9]* vulnerabilities in modules you require" /tmp/vuln_raw.txt | grep -o "[0-9]*" | head -1); \
			echo "**Status:** ✅ No direct vulnerabilities found" >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo "**Note:** Found $$indirect_count vulnerabilities in indirect dependencies, but your code doesn't appear to call the vulnerable functions." >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo "**Recommendation:** Monitor these dependencies and update when convenient." >> deps-report.md; \
		else \
			echo "**Status:** ✅ Scan completed successfully" >> deps-report.md; \
		fi; \
		echo "" >> deps-report.md; \
		echo "<details>" >> deps-report.md; \
		echo "<summary>🔍 Click to view full scan results</summary>" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo '```' >> deps-report.md; \
		cat /tmp/vuln_raw.txt >> deps-report.md; \
		echo '```' >> deps-report.md; \
		echo "</details>" >> deps-report.md; \
	fi; \
	rm -f /tmp/vuln_raw.txt; \
	echo "" >> deps-report.md; \
	echo "**Last Scan:** $$(date)" >> deps_report.md; \
	echo "**Scanner Version:** $$(govulncheck -version 2>/dev/null | head -1 || echo 'govulncheck not available')" >> deps-report.md; \
	echo "**Go Version:** $$(go version)" >> deps-report.md

# Run vulnerability scan with formatted output
.PHONY: _run-vuln-scan
_run-vuln-scan:
	@echo "Running vulnerability scan..." >&2
	@govulncheck ./... > /tmp/vuln_raw.txt 2>&1 || true; \
	if [ ! -s /tmp/vuln_raw.txt ]; then \
		echo "### ❌ Vulnerability Scanner Not Available" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "The \`govulncheck\` tool is not installed or not working properly." >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Installation:** \`go install golang.org/x/vuln/cmd/govulncheck@latest\`" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Alternative:** Run \`make install-tools\` to install required tools." >> deps-report.md; \
	elif grep -q "No vulnerabilities found" /tmp/vuln_raw.txt; then \
		echo "### ✅ No Vulnerabilities Found" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "Great news! No known security vulnerabilities were detected in your dependencies." >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**Scan Status:** ✅ Complete" >> deps-report.md; \
		echo "**Vulnerabilities Found:** 0" >> deps-report.md; \
		echo "**Action Required:** None" >> deps-report.md; \
	elif grep -q "Your code is affected by" /tmp/vuln_raw.txt; then \
		vuln_count=$$(grep -o "affected by [0-9]* vulnerabilities" /tmp/vuln_raw.txt | grep -o "[0-9]*" | head -1); \
		echo "### ⚠️ Security Vulnerabilities Detected ($$vuln_count found)" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "**⚠️ Action Required:** Your code is directly affected by $$vuln_count vulnerabilities." >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "| # | Vulnerability ID | Affected Package | Description | Status |" >> deps-report.md; \
		echo "|---|------------------|------------------|-------------|--------|" >> deps-report.md; \
		counter=1; \
		grep -A 20 "Vulnerability #" /tmp/vuln_raw.txt | while IFS= read -r line; do \
			if echo "$$line" | grep -q "Vulnerability #"; then \
				vuln_id=$$(echo "$$line" | sed 's/Vulnerability #[0-9]*: //'); \
				read -r description; \
				read -r more_info; \
				read -r source_info; \
				read -r found_in; \
				read -r fixed_in; \
				package=$$(echo "$$found_in" | sed 's/.*Found in: //' | sed 's/@.*//' || echo "Unknown"); \
				fix_version=$$(echo "$$fixed_in" | sed 's/.*Fixed in: //' || echo "See advisory"); \
				desc_short=$$(echo "$$description" | head -c 60)...; \
				url=$$(echo "$$more_info" | grep -o "https://[^[:space:]]*" || echo ""); \
				if [ -n "$$url" ]; then \
					vuln_link="[$$vuln_id]($$url)"; \
				else \
					vuln_link="$$vuln_id"; \
				fi; \
				echo "| $$counter | $$vuln_link | \`$$package\` | $$desc_short | 🔴 **Update Required** |" >> deps-report.md; \
				counter=$$((counter + 1)); \
			fi; \
		done; \
		echo "" >> deps-report.md; \
		echo "#### 📋 Detailed Vulnerability Information" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo "<details>" >> deps-report.md; \
		echo "<summary>🔍 Click to view detailed vulnerability scan results</summary>" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo '```' >> deps-report.md; \
		cat /tmp/vuln_raw.txt >> deps-report.md; \
		echo '```' >> deps-report.md; \
		echo "</details>" >> deps-report.md; \
	else \
		echo "### ⚠️ Vulnerability Scan Completed" >> deps-report.md; \
		echo "" >> deps-report.md; \
		if grep -q "vulnerabilities in modules you require" /tmp/vuln_raw.txt; then \
			indirect_count=$$(grep -o "[0-9]* vulnerabilities in modules you require" /tmp/vuln_raw.txt | grep -o "[0-9]*" | head -1); \
			echo "**Status:** ✅ No direct vulnerabilities found" >> deps-report.md; \
			echo "" >> deps-report.md; \
			echo "**Note:** Found $$indirect_count vulnerabilities in indirect dependencies, but your code doesn't appear to call the vulnerable functions." >> deps-report.md; \
		else \
			echo "**Status:** ✅ Scan completed successfully" >> deps-report.md; \
		fi; \
		echo "" >> deps-report.md; \
		echo "<details>" >> deps-report.md; \
		echo "<summary>🔍 Click to view full scan results</summary>" >> deps-report.md; \
		echo "" >> deps-report.md; \
		echo '```' >> deps-report.md; \
		cat /tmp/vuln_raw.txt >> deps-report.md; \
		echo '```' >> deps-report.md; \
		echo "</details>" >> deps-report.md; \
	fi; \
	rm -f /tmp/vuln_raw.txt; \
	echo "" >> deps-report.md; \
	echo "#### 🛡️ Security Recommendations" >> deps-report.md; \
	echo "" >> deps-report.md; \
	echo "1. **Regular Scanning**: Run \`make vuln-check\` regularly to catch new vulnerabilities" >> deps-report.md; \
	echo "2. **Dependency Updates**: Keep dependencies up to date, especially security patches" >> deps-report.md; \
	echo "3. **Monitoring**: Consider automated vulnerability monitoring in CI/CD pipelines" >> deps-report.md; \
	echo "4. **Review Process**: Evaluate each vulnerability for actual impact on your application" >> deps-report.md; \
	echo "5. **Go Updates**: Keep your Go version updated to get standard library security fixes" >> deps-report.md; \
	echo "" >> deps-report.md; \
	echo "**Last Scan:** $$(date)" >> deps-report.md; \
	echo "**Scanner Version:** $$(govulncheck -version 2>/dev/null | head -1 || echo 'govulncheck not available')" >> deps-report.md; \
	echo "**Go Version:** $$(go version)" >> deps-report.md

# Fast maintenance info based on GitHub API with timeout
.PHONY: _get-maintenance-info
_get-maintenance-info:
	@if [ -z "$(DEP)" ]; then echo "❓ Unknown"; exit 0; fi
	@case "$(DEP)" in \
		github.com/*) \
			repo_path=$$(echo "$(DEP)" | sed 's|github.com/||' | sed 's|/v[0-9].*||'); \
			api_url="https://api.github.com/repos/$$repo_path"; \
			if [ -n "$$GITHUB_CREDENTIALS" ]; then \
				repo_data=$$(curl -s --max-time 5 -H "Authorization: token $$GITHUB_CREDENTIALS" -H "Accept: application/vnd.github.v3+json" "$$api_url" 2>/dev/null); \
			else \
				repo_data=$$(curl -s --max-time 3 "$$api_url" 2>/dev/null); \
			fi; \
			if echo "$$repo_data" | jq -e '.pushed_at' >/dev/null 2>&1; then \
				last_push=$$(echo "$$repo_data" | jq -r '.pushed_at' | cut -d'T' -f1); \
				if date -d "$$last_push" >/dev/null 2>&1; then \
					push_epoch=$$(date -d "$$last_push" +%s 2>/dev/null); \
					current_epoch=$$(date +%s); \
					days_ago=$$(( (current_epoch - push_epoch) / 86400 )); \
				elif date -j -f "%Y-%m-%d" "$$last_push" >/dev/null 2>&1; then \
					push_epoch=$$(date -j -f "%Y-%m-%d" "$$last_push" +%s 2>/dev/null); \
					current_epoch=$$(date +%s); \
					days_ago=$$(( (current_epoch - push_epoch) / 86400 )); \
				else \
					days_ago=999; \
				fi; \
				if [ "$$days_ago" -le 90 ]; then \
					echo "🟢 Active ($$last_push)"; \
				elif [ "$$days_ago" -le 180 ]; then \
					echo "🟡 Moderate ($$last_push)"; \
				elif [ "$$days_ago" -le 365 ]; then \
					echo "🟠 Slow ($$last_push)"; \
				else \
					echo "🔴 Stale ($$last_push)"; \
				fi; \
			elif echo "$$repo_data" | jq -e '.message' >/dev/null 2>&1; then \
				error_msg=$$(echo "$$repo_data" | jq -r '.message'); \
				if echo "$$error_msg" | grep -q "rate limit"; then \
					echo "⏱️ Rate limited"; \
				else \
					echo "❓ API Error"; \
				fi; \
			else \
				echo "❓ Unknown"; \
			fi ;; \
		*) \
			echo "❓ Non-GitHub"; \
	esac
