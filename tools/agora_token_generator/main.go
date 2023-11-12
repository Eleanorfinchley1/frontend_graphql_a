package main

import (
	"flag"
	"fmt"
	rtctokenbuilder "github.com/AgoraIO/Tools/DynamicKey/AgoraDynamicKey/go/src/RtcTokenBuilder"
	"os"
	"time"
)

func generateRtcToken(appID, appCertificate, channelName string, uid, ttl uint32, role rtctokenbuilder.Role) (result string, err error) {
	expireTimestamp := uint32(time.Now().UTC().Unix()) + ttl
	result, err = rtctokenbuilder.BuildTokenWithUID(appID, appCertificate, channelName, uid, role, expireTimestamp)
	return
}

func mapRoleName(roleName string) (role rtctokenbuilder.Role, err error) {
	switch roleName {
	case "publisher":
		role = rtctokenbuilder.RolePublisher
	case "subscriber":
		role = rtctokenbuilder.RoleSubscriber
	default:
		err = fmt.Errorf("Invalid role name: %s", roleName)
	}

	return
}

func main() {
	var appID string
	var appCertificate string
	var channelName string
	var roleName string
	var ttl uint
	var uid uint

	flag.StringVar(&appID, "appID", "", "App ID (required)")
	flag.StringVar(&appCertificate, "appCertificate", "", "App certificate (required)")
	flag.StringVar(&channelName, "channelName", "", "Channel name (required)")
	flag.StringVar(&roleName, "role", "subscriber", "publisher or subscriber")
	flag.UintVar(&uid, "uid", 0, "Unique user id (default 0, unused)")
	flag.UintVar(&ttl, "ttl", 3600, "Token TTL in seconds")

	flag.Parse()

	if appID == "" {
		fmt.Fprintln(os.Stderr, "appID is required")
		os.Exit(1)
	}

	if appCertificate == "" {
		fmt.Fprintln(os.Stderr, "appCertificate is required")
		os.Exit(1)
	}

	if channelName == "" {
		fmt.Fprintln(os.Stderr, "channelName is required")
		os.Exit(1)
	}

	role, err := mapRoleName(roleName)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s", err)
		os.Exit(2)
	}

	token, err := generateRtcToken(appID, appCertificate, channelName, uint32(uid), uint32(ttl), role)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %s", err)
		os.Exit(3)
	}

	fmt.Printf("%s", token)
}
