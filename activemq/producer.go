package main

import (
	"log"
	"net"

	"github.com/go-stomp/stomp"
)

func main() {
	// Establish connection
	conn, err := net.Dial("tcp", "localhost:61613")
	if err != nil {
		log.Fatalf("failed to connect to ActiveMQ: %v", err)
	}
	stompConn, err := stomp.Connect(conn)
	if err != nil {
		log.Fatalf("failed to connect to STOMP server: %v", err)
	}
	defer stompConn.Disconnect()

	// Send a message
	destination := "/queue/test"
	body := "Hello, ActiveMQ!"
	err = stompConn.Send(
		destination,
		"text/plain",
		[]byte(body),
	)
	if err != nil {
		log.Fatalf("failed to send message: %v", err)
	}
	log.Printf("Message sent to %s: %s", destination, body)
}
