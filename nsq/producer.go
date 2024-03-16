package main

import (
	"log"

	"github.com/nsqio/go-nsq"
)

func main() {
	// Create a producer instance
	config := nsq.NewConfig()
	producer, err := nsq.NewProducer("localhost:4150", config)
	if err != nil {
		log.Fatal(err)
	}

	// Publish a message to the 'test' topic
	messageBody := []byte("Hello NSQ!")
	if err := producer.Publish("test", messageBody); err != nil {
		log.Fatal("Publish error:", err)
	}

	log.Println("Message published:", string(messageBody))
	producer.Stop()
}
