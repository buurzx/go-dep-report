package main

import (
	_ "embed"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
)

//go:embed Makefile
var embeddedMakefile []byte

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Usage: go-dep-report <go-service-dir> <output-dir>")
		os.Exit(1)
	}
	serviceDir := os.Args[1]
	outputDir := os.Args[2]

	reportFile := "deps-report.md"

	// Write embedded Makefile to a temporary file
	tmpMakefile, err := os.CreateTemp("", "go-dep-report-makefile-*.mk")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error creating temp Makefile: %v\n", err)
		os.Exit(1)
	}
	defer os.Remove(tmpMakefile.Name())
	if _, err := tmpMakefile.Write(embeddedMakefile); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing to temp Makefile: %v\n", err)
		os.Exit(1)
	}
	tmpMakefile.Close()

	// Run `make -f <tmpMakefile> deps-report` in the service directory
	cmd := exec.Command("make", "-f", tmpMakefile.Name(), "deps-report")
	cmd.Dir = serviceDir
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "Error running make deps-report: %v\n", err)
		os.Exit(1)
	}

	// Ensure the output directory exists
	if err := os.MkdirAll(outputDir, 0755); err != nil {
		fmt.Fprintf(os.Stderr, "Error creating output directory: %v\n", err)
		os.Exit(1)
	}

	// Move the report to the output directory
	source := filepath.Join(serviceDir, reportFile)
	dest := filepath.Join(outputDir, reportFile)
	if err := os.Rename(source, dest); err != nil {
		fmt.Fprintf(os.Stderr, "Error moving report: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Report generated at: %s\n", dest)
}
