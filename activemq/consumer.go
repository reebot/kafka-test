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

	// Subscribe to the queue
	sub, err := stompConn.Subscribe("/queue/test", stomp.AckAuto)
	if err != nil {
		log.Fatalf("failed to subscribe to queue: %v", err)
	}
	defer sub.Unsubscribe()

	// Receive messages
	for {
		msg, ok := <-sub.C
		if !ok {
			log.Println("Subscription channel closed")
			break
		}
		if msg == nil {
			log.Println("Received nil message")
			continue
		}
		log.Printf("Received message: %s", string(msg.Body))
	}
}
