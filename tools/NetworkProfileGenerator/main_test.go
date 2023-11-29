package main

import (
	"flag"
	"os"
	"testing"
)

type TestCase struct {
	Input  string
	Output string
	Golden string
}

func TestMainFunction(t *testing.T) {
	testCases := []TestCase{
		{Input: "./test/input1.json", Output: "./test/output1.sh", Golden: "./test/golden1.sh"},
		{Input: "./test/input2.json", Output: "./test/output2.sh", Golden: "./test/golden2.sh"},
	}

	for _, tc := range testCases {
		// Backup command line arguments and restore them at the end of the test
		oldArgs := os.Args
		defer func() { os.Args = oldArgs }()

		// Set command line arguments for the test
		os.Args = []string{"cmd", "-input=" + tc.Input, "-output="+ tc.Output}

		// Reset the flag set to clear flags defined in other tests
		flag.CommandLine = flag.NewFlagSet(os.Args[0], flag.ExitOnError)

		main()

		// Read the output file
		output, err := os.ReadFile(tc.Output)
		if err != nil {
			t.Fatalf("Failed to read output file: %v", err)
		}

		// Read the golden file
		golden, err := os.ReadFile(tc.Golden)
		if err != nil {
			t.Fatalf("Failed to read golden file: %v", err)
		}

		// Compare the output to the golden file
		if string(output) != string(golden) {
			t.Errorf("Output does not match the golden file for input %s", tc.Input)
		}
	}
}