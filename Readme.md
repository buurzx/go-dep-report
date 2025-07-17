### 📋 Overview
Security reporting system for the Go projects, addressing the critical need for dependency security monitoring and license compliance tracking.

### Report example
https://github.com/buurzx/go-dep-report/example_report/deps-report.md


### 🚀 Quick Start

1. **Install the CLI tool:**
   ```bash
   go install github.com/buurzx/go-dep-report@latest
   ```

2. **Generate a dependency report:**
   ```bash
   go-dep-report /path/to/your/go/project /path/to/output/dir
   ```

   - The first argument is the path to your Go project directory.
   - The second argument is the path to the output directory for the report (`deps-report.md`).

3. **Example:**
   ```bash
   go-dep-report ~/projects/my-service ~/reports
   # The report will be available at: ~/reports/deps-report.md
   ```

> The tool requires the Makefile from the go-dep-report repository.
> During execution, it runs `make deps-report` inside your project directory.

### 🔧 Key Features Implemented

#### 1. **Advanced Dependency Analysis**
- **42 direct dependencies** analyzed with security and license information
- Automatic detection of outdated packages with update recommendations
- License categorization with compliance risk assessment
- Maintenance status tracking based on GitHub API integration

#### 2. **Security Vulnerability Scanning**
- Integration with `govulncheck` for automated vulnerability detection
- Automatic code generation if compilation fails
- Comprehensive vulnerability reporting in markdown format

#### 3. **GitHub API Integration**
- Enhanced rate limits (5000 req/hour) with GitHub token authentication
- Fallback to unauthenticated API (60 req/hour) when no token provided
- Real-time repository maintenance status tracking
- License detection from GitHub repository metadata

#### 4. **Comprehensive Reporting Dashboard**
- **License Risk Assessment**:
  - ✅ 23 Permissive licenses (MIT, Apache-2.0, BSD)
  - ⚠️ 0 Copyleft licenses detected
  - ❓ 19 licenses requiring manual review
- **Update Status**: 17 packages with available updates identified
- **Version Freshness**: Color-coded indicators for package age
- **Maintenance Health**: Real-time activity status from GitHub

#### 5. **Third-Party API Integration Tracking**
- Template system for documenting external API dependencies
- Security and compliance tracking for external integrations
- Rate limiting and error handling documentation

### 🛠️ Available Make Commands

```bash
make install-tools      # Install required tools (govulncheck, jq, curl)
make check-tools        # Verify all required tools are installed
make check-github-api   # Test GitHub API connection and rate limits
make vuln-check         # Run vulnerability scan (auto-generates code if needed)
make deps-report        # Generate comprehensive dependency report
make deps-help              # Show all available commands
```

### 🔍 Key Findings from Initial Report

- **Security Status**: 4 vulnerabilities detected by GitHub (1 high, 3 moderate)
- **License Compliance**: All detected licenses are permissive (MIT, Apache-2.0, BSD)
- **Update Opportunities**: 17 packages have newer versions available
- **Maintenance Health**: Most packages actively maintained, few stale dependencies identified

### 💡 Benefits

1. **Security Posture**: Proactive vulnerability detection and monitoring
2. **License Compliance**: Automated license risk assessment for legal compliance
3. **Maintenance Visibility**: Clear insight into dependency health and update needs
4. **Team Awareness**: Comprehensive documentation of all external dependencies
5. **Automation Ready**: Integrates with CI/CD pipelines for continuous monitoring
