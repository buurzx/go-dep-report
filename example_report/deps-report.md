# Dependency Security & License Report
Generated: Thu Jul 17 15:25:37 MSK 2025

## 🔍 Vulnerability Scan Results

_Scanning for known security vulnerabilities in dependencies..._

### 🚨 CRITICAL: Security Vulnerabilities Detected ( found)

**⚠️ IMMEDIATE ACTION REQUIRED:** Your code is directly affected by  vulnerabilities.

| # | Vulnerability ID | Description | Found In | Fixed In | Status |
|---|------------------|-------------|----------|----------|--------|
| 1 | GO-2025-3750 |     Inconsistent handling of O_CREATE|O_EXCL ... | `  Standard library` | `    Found in: os@go1.23.5` | 🚨 **UPDATE NOW** |

#### 🛠️ Immediate Actions Required

1. **🔴 HIGH PRIORITY**: Update Go to the latest version to fix standard library vulnerabilities
2. **📋 Security Review**: Check the example traces below to see if your code uses vulnerable paths
3. **🔧 Update Dependencies**: Run `go mod tidy && go get -u` for affected packages
4. **✅ Re-scan**: Run `make vuln-check` after updates to verify fixes

#### 📋 Vulnerability Details & Example Traces

<details>
<summary><strong>1. GO-2025-3750</strong> - Click to view details</summary>

**Description:**     Inconsistent handling of O_CREATE|O_EXCL on Unix and Windows in os in

**Source:**   More info: https://pkg.go.dev/vuln/GO-2025-3750
**Found in:** `  Standard library`
**Fixed in:** `    Found in: os@go1.23.5`

**Example traces in your code:**
```
    Fixed in: os@go1.23.10
    Platforms: windows
    Example traces found:
      #1: internal/network/tcp/server.go:8:2: tcp.init calls os.init, which calls os.Getwd
      #2: internal/network/tcp/server.go:8:2: tcp.init calls os.init, which calls os.NewFile
      #3: internal/network/tcp/server.go:71:25: tcp.TCPServer.Close calls net.UnixListener.Close, which eventually calls os.Open
      #4: cmd/kvcli/config.go:34:31: kvcli.mustParseConfiguration calls cleanenv.ReadConfig, which eventually calls os.OpenFile
      #5: cmd/main.go:22:16: cmd.main calls cli.App.Run, which eventually calls os.ReadFile
      #6: cmd/main.go:22:16: cmd.main calls cli.App.Run, which eventually calls os.Stat
      #7: internal/network/tcp/server.go:8:2: tcp.init calls os.init, which eventually calls syscall.Open

```

</details>


**Scanner Version:** Go: go1.23.5
**Go Version:** go version go1.23.5 darwin/arm64

## 📦 Direct Dependencies

| Package | Description | Current | Latest | Version Date | License | Maintenance |
|---------|-------------|---------|--------|--------------|---------|-------------|
| [ilyakaznacheev/cleanenv](https://github.com/ilyakaznacheev/cleanenv) | [📝 Edit](#ilyakaznacheev-cleanenv) | `v1.5.0` | ✅ current | 🔴 2023-07-20 | MIT (✅ Permissive) | 🟠 Slow (2025-01-05) |
| [stretchr/testify](https://github.com/stretchr/testify) | [📝 Edit](#stretchr-testify) | `v1.10.0` | ✅ current | 🟠 2024-11-12 | MIT (✅ Permissive) | 🟢 Active (2025-07-01) |
| [urfave/cli/v2](https://github.com/urfave/cli/v2) | [📝 Edit](#urfave-cli-v2) | `v2.27.5` | ⚠️ v2.27.7 | 🟠 2024-10-13 | MIT (✅ Permissive) | 🟢 Active (2025-07-13) |
| [uber-go/zap](https://github.com/uber-go/zap) | [📝 Edit](#go-uber-org-zap) | `v1.27.0` | ✅ current | 🔴 2024-02-20 | ❓ Not detected | ❓ Non-GitHub |

## 📝 Package Descriptions

_Edit this section to add descriptions for each dependency. This helps team members understand why each package is used and how it fits into the project._

### ilyakaznacheev-cleanenv

**Package:** `github.com/ilyakaznacheev/cleanenv`

**Purpose:** _[Add description here - What does this package do? Why is it used?]_

**Usage:** _[Add usage details - How is it used in the project?]_

**Notes:** _[Add any important notes, alternatives, or migration plans]_

### stretchr-testify

**Package:** `github.com/stretchr/testify`

**Purpose:** _[Add description here - What does this package do? Why is it used?]_

**Usage:** _[Add usage details - How is it used in the project?]_

**Notes:** _[Add any important notes, alternatives, or migration plans]_

### urfave-cli-v2

**Package:** `github.com/urfave/cli/v2`

**Purpose:** _[Add description here - What does this package do? Why is it used?]_

**Usage:** _[Add usage details - How is it used in the project?]_

**Notes:** _[Add any important notes, alternatives, or migration plans]_

### go-uber-org-zap

**Package:** `go.uber.org/zap`

**Purpose:** _[Add description here - What does this package do? Why is it used?]_

**Usage:** _[Add usage details - How is it used in the project?]_

**Notes:** _[Add any important notes, alternatives, or migration plans]_


## 🌐 Third-Party API Integrations

_This section documents external APIs and services that the application integrates with. Regular review helps ensure security, compliance, and maintenance of these integrations._

---

### google-maps-api

**Service:** Google Maps Platform API

**Endpoint:** `https://maps.googleapis.com/maps/api/geocode/json`

**Purpose:** _[Add description - Geocoding addresses to coordinates for location services]_

**Authentication:** _[API Key / OAuth / Basic Auth]_

**Rate Limits:** _[1000 requests/day, 50 requests/second]_

**Data Sensitivity:** _[PII/Location data - describe what data is sent]_

**Error Handling:** _[Timeout: 5s, Retry: 3x with exponential backoff]_

**Monitoring:** _[Metrics tracked, alerts configured]_

**Security:** _[SSL/TLS encryption, certificate validation, credential storage]_

**Last Reviewed:** _[Date - when was this integration last audited]_

**Notes:** _[Migration plans, known issues, alternatives considered]_

---

### Template for New Integration

**Service:** _[Service Name and Provider]_

**Endpoint:** _[Primary API endpoint URL]_

**Purpose:** _[What does this integration do? Why do we need it?]_

**Authentication:** _[How do we authenticate? API key, OAuth, etc.]_

**Rate Limits:** _[What are the usage limits? How do we handle them?]_

**Data Sensitivity:** _[What data do we send? Any PII or sensitive information?]_

**Error Handling:** _[How do we handle failures? Timeouts, retries, fallbacks?]_

**Monitoring:** _[What metrics do we track? What alerts are configured?]_

**Security:** _[SSL/TLS, certificate validation, credential storage, encryption]_

**Last Reviewed:** _[When was this integration last reviewed for security/compliance?]_

**Notes:** _[Any important notes, compliance requirements, or future plans?]_

## 📋 License Categories
- ✅ **Permissive**: MIT, Apache-2.0, BSD, ISC, Unlicense - Generally safe for commercial use
- ⚠️ **Weak Copyleft**: MPL-2.0, EPL, CDDL - May require source disclosure for modifications
- ⚠️ **Copyleft**: GPL, AGPL, LGPL - Strong copyleft requirements
- ⚠️ **Commercial/Proprietary**: Requires commercial licensing
- ⚠️ **Non-Commercial**: Restricted to non-commercial use only
- ❓ **Not detected**: License could not be automatically detected - manual review required
- ❓ **Review needed**: Unusual license requiring manual review

## 📊 Update Status Legend
- ✅ **Current**: Using the latest available version
- ⚠️ **Update Available**: Newer version available (shows version number)
- 🔧 **Custom Fork**: Using a custom fork or replace directive - **requires manual review**

## 📊 Version Date Legend
- 🟢 **Recent**: Version released within 3 months
- 🟡 **Moderate**: Version released within 6 months
- 🟠 **Old**: Version released within 1 year
- 🔴 **Very Old**: Version released over 1 year ago
- ❓ **Unknown**: Could not determine version date

## 🔧 Maintenance Status Legend
- 🟢 **Active/Recent**: Last commit or version within 3 months
- 🟡 **Moderate**: Last commit or version within 6 months
- 🟠 **Slow/Old**: Last commit or version within 1 year
- 🔴 **Stale/Very Old**: Last commit or version over 1 year ago
- ⏱️ **Rate limited**: GitHub API rate limit exceeded
- ❓ **Unknown**: Could not determine maintenance status

## 🔑 GitHub API Integration
- ✅ **Enhanced Mode**: Using authenticated GitHub API (5000 requests/hour)

