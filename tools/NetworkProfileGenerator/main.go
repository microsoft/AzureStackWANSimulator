package main

// Download Traffic Control Rule Only

import (
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"strings"
)

type Rule struct {
	Name    string   `json:"name"`
	Id      int      `json:"id"`
	BwRate  string   `json:"bwRate"`
	Delay   string   `json:"delay"`
	Loss    string   `json:"loss"`
	Subnets []string `json:"subnets"`
}

const (
	rootClass = "1a1a:"
	protocol  = "protocol ip"
	sudoTc    = "sudo tc"
)

func main() {

	var inputJson string
	var outputSh string
	var vmIntfs string
	var direction string

	flag.StringVar(&inputJson, "input", "profile_input.json", "Input JSON file")
	flag.StringVar(&outputSh, "output", "profile_rules.sh", "Output shell script file")
	flag.StringVar(&vmIntfs, "vmIntfs", "gre1,gre2", "Comma-separated list of VM interfaces")
	flag.StringVar(&direction, "direction", "dst", "Direction of traffic (src/dst)")
	flag.Parse()

	vmIntfsSlice := strings.Split(vmIntfs, ",")

	jsonFile, err := os.Open(inputJson)
	if err != nil {
		log.Fatalln("Error opening JSON file:", err)
		return
	}
	defer jsonFile.Close()

	byteValue, _ := io.ReadAll(jsonFile)

	var rules []Rule
	json.Unmarshal(byteValue, &rules)

	file, err := os.Create(outputSh)
	if err != nil {
		log.Fatalln("Error creating file: ", err)
		return
	}
	fmt.Println("Profile Rule Created: ", outputSh)
	defer file.Close()

	for _, vmIntf := range vmIntfsSlice {
		writeToFile(file, "# TC Rule for %s\n", vmIntf)
		for _, rule := range rules {
			writeToFile(file, "# %s\n", rule.Name)
			if rule.Id == 1 {
				writeToFile(file, "%s qdisc add dev %s root handle %s htb default %d\n", sudoTc, vmIntf, rootClass, rule.Id)
			}
			writeToFile(file, "%s class add dev %s parent %s classid %s%d htb rate %s\n", sudoTc, vmIntf, rootClass, rootClass, rule.Id, rule.BwRate)

			if rule.Delay != "" && rule.Loss != "" {
				writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem delay %s loss %s\n", sudoTc, vmIntf, rootClass, rule.Id, rule.Id, rule.Delay, rule.Loss)
			} else if rule.Delay != "" {
				writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem delay %s\n", sudoTc, vmIntf, rootClass, rule.Id, rule.Id, rule.Delay)
			} else if rule.Loss != "" {
				writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem loss %s\n", sudoTc, vmIntf, rootClass, rule.Id, rule.Id, rule.Loss)
			}

			for _, subnet := range rule.Subnets {
				writeToFile(file, "%s filter add dev %s %s parent %s prio 1 u32 match ip %s %s flowid %s%d\n", sudoTc, vmIntf, protocol, rootClass, direction, subnet, rootClass, rule.Id)
			}
		}
	}
}

func writeToFile(file *os.File, format string, a ...interface{}) {
	_, err := fmt.Fprintf(file, format, a...)
	if err != nil {
		log.Fatalln(err)
	}
}
