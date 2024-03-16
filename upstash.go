package main

import (
	"context"
	"crypto/tls"
	"log"
	"os"

	"github.com/segmentio/kafka-go"
	"github.com/segmentio/kafka-go/sasl/scram"
)

func Producer(topic string) {
	// Load Kafka details from environment variables
	url := os.Getenv("KAFKA_URL")
	username := os.Getenv("KAFKA_USERNAME")
	password := os.Getenv("KAFKA_PASSWORD")

	mechanism, err := scram.Mechanism(scram.SHA256, username, password)
	if err != nil {
		log.Fatalf("could not create mechanism: %v", err)
	}

	w := kafka.Writer{
		Addr:  kafka.TCP(url),
		Topic: topic,
		Transport: &kafka.Transport{
			SASL: mechanism,
			TLS:  &tls.Config{},
		},
	}

	err = w.WriteMessages(context.Background(),
		kafka.Message{
			Key:   []byte("second"),
			Value: []byte("test"),
		},
	)
	if err != nil {
		log.Fatalf("failed to write messages: %v", err)
	}
	w.Close()
}

func main() {
	Producer("coins")
}
