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
	RuleID      int      `json:"RuleID"`
	RuleName    string   `json:"RuleName"`
	DownloadBW  string   `json:"DownloadBW"`
	DownloadDelay   string   `json:"DownloadDelay"`
	DownloadLoss    string   `json:"DownloadLoss"`
	AppliedSubnets []string `json:"AppliedSubnets"`
	UploadBW  string   `json:"UploadBW"`
	UploadDelay   string   `json:"UploadDelay"`
	UploadLoss    string   `json:"UploadLoss"`
}

const (
	rootClass = "1a1a:"
	protocol  = "protocol ip"
	sudoTc    = "sudo tc"
	uploadDirection = "src"
	downloadDirection = "dst"
	htbDefaultId = 1
)

func main() {

	var inputJson string
	var outputSh string
	var outboundIntf string
	var inboundIntfs string
	var outboundBW string
	var inboundBW string

	flag.StringVar(&inputJson, "input", "profile_input.json", "Input JSON file")
	flag.StringVar(&outputSh, "output", "profile_rules.sh", "Output shell script file")
	flag.StringVar(&outboundIntf, "outboundIntf", "eth0", "VM interfaces for outbound traffic")
	flag.StringVar(&inboundIntfs, "inboundIntfs", "gre1,gre2", "Comma-separated list of VM interfaces for inbound traffic")
	flag.StringVar(&outboundBW, "outboundBW", "1Gbit", "Total Upload Bandwidth for all Subnets")
	flag.StringVar(&inboundBW, "inboundBW", "1Gbit", "Total Download Bandwidth for all Subnets")
	flag.Parse()

	inboundIntfsSlice := strings.Split(inboundIntfs, ",")

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

	// Upload Network Profile Rules
	writeToFile(file, "# TC Rule for Upload\n")
	writeToFile(file, "%s qdisc add dev %s root handle %s htb default %d\n", sudoTc, outboundIntf, rootClass, htbDefaultId)
	writeToFile(file, "%s class add dev %s parent %s classid %s%d htb rate %s\n", sudoTc, outboundIntf, rootClass, rootClass, htbDefaultId, outboundBW)
	for _, rule := range rules {
		if rule.UploadBW ==""{
			log.Fatalln("Upload Bandwidth is not defined for rule: ", rule.RuleName)
		}
		writeToFile(file, "# %s\n", rule.RuleName)
		writeToFile(file, "%s class add dev %s parent %s classid %s%d htb rate %s\n", sudoTc, outboundIntf, rootClass, rootClass, rule.RuleID, rule.UploadBW)
		if rule.UploadDelay != "" && rule.UploadLoss != "" {
			writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem delay %s loss %s\n", sudoTc, outboundIntf, rootClass, rule.RuleID, rule.RuleID, rule.UploadDelay, rule.UploadLoss)
		} else if rule.UploadDelay != "" {
			writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem delay %s\n", sudoTc, outboundIntf, rootClass, rule.RuleID, rule.RuleID, rule.UploadDelay)
		} else if rule.UploadLoss != "" {
			writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem loss %s\n", sudoTc, outboundIntf, rootClass, rule.RuleID, rule.RuleID, rule.UploadLoss)
		}

		for _, subnet := range rule.AppliedSubnets {
			writeToFile(file, "%s filter add dev %s %s parent %s prio 1 u32 match ip %s %s flowid %s%d\n", sudoTc, outboundIntf, protocol, rootClass, uploadDirection, subnet, rootClass, rule.RuleID)
		}
	}


	// Download Network Profile Rules
	writeToFile(file, "# TC Rule for Download\n")
	for _, vmIntf := range inboundIntfsSlice {
		writeToFile(file, "# TC Rule for %s\n", vmIntf)
		writeToFile(file, "%s qdisc add dev %s root handle %s htb default %d\n", sudoTc, vmIntf, rootClass, htbDefaultId)
		writeToFile(file, "%s class add dev %s parent %s classid %s%d htb rate %s\n", sudoTc, vmIntf, rootClass, rootClass, htbDefaultId, inboundBW)
		for _, rule := range rules {
			if rule.DownloadBW ==""{
				log.Fatalln("Download Bandwidth is not defined for rule: ", rule.RuleName)
			}
			writeToFile(file, "# %s\n", rule.RuleName)
			writeToFile(file, "%s class add dev %s parent %s classid %s%d htb rate %s\n", sudoTc, vmIntf, rootClass, rootClass, rule.RuleID, rule.DownloadBW)
			if rule.DownloadDelay != "" && rule.DownloadLoss != "" {
				writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem delay %s loss %s\n", sudoTc, vmIntf, rootClass, rule.RuleID, rule.RuleID, rule.DownloadDelay, rule.DownloadLoss)
			} else if rule.DownloadDelay != "" {
				writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem delay %s\n", sudoTc, vmIntf, rootClass, rule.RuleID, rule.RuleID, rule.DownloadDelay)
			} else if rule.DownloadLoss != "" {
				writeToFile(file, "%s qdisc add dev %s parent %s%d handle %d netem loss %s\n", sudoTc, vmIntf, rootClass, rule.RuleID, rule.RuleID, rule.DownloadLoss)
			}

			for _, subnet := range rule.AppliedSubnets {
				writeToFile(file, "%s filter add dev %s %s parent %s prio 1 u32 match ip %s %s flowid %s%d\n", sudoTc, vmIntf, protocol, rootClass, downloadDirection, subnet, rootClass, rule.RuleID)
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
