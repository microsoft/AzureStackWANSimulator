package main

import (
	"flag"
	"os"
	"testing"
)

func TestMainFunction(t *testing.T) {
	// Backup command line arguments and restore them at the end of the test
	oldArgs := os.Args
	defer func() { os.Args = oldArgs }()

	// Set command line arguments for the test
	os.Args = []string{"cmd", "-input=./test/input.json", "-output=./test/output.sh", "-vmIntfs=gre1,gre2"}

	// Reset the flag set to clear flags defined in other tests
	flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)

	main()

	// Read the output file
	output, err := os.ReadFile("./test/output.sh")
	if err != nil {
		t.Fatalf("Failed to read output file: %v", err)
	}

	// Read the golden file
	golden, err := os.ReadFile("./test/golden.sh")
	if err != nil {
		t.Fatalf("Failed to read golden file: %v", err)
	}

	// Compare the output to the golden file
	if string(output) != string(golden) {
		t.Errorf("Output does not match golden file")
	}
}
