package main

import (
	"log"

	"github.com/nsqio/go-nsq"
)

func main() {
	// Create a consumer instance
	config := nsq.NewConfig()
	consumer, err := nsq.NewConsumer("test", "test_channel", config)
	if err != nil {
		log.Fatal(err)
	}

	// Handler for messages
	consumer.AddHandler(nsq.HandlerFunc(func(message *nsq.Message) error {
		log.Println("Received message:", string(message.Body))
		return nil
	}))

	// Connect to the NSQD
	if err := consumer.ConnectToNSQD("localhost:4150"); err != nil {
		log.Fatal("Connect error:", err)
	}

	// Wait for messages
	select {}
}
