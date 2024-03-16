package main

import (
	"fmt"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

func main() {
	// Define producer configuration
	config := &kafka.ConfigMap{"bootstrap.servers": "localhost:9094"}

	// Create a new producer
	producer, err := kafka.NewProducer(config)
	if err != nil {
		panic(err)
	}

	// Ensure resources are released back when the function exits
	defer producer.Close()

	// Delivery report handler for produced messages
	go func() {
		for e := range producer.Events() {
			switch ev := e.(type) {
			case *kafka.Message:
				if ev.TopicPartition.Error != nil {
					fmt.Printf("Failed to deliver message: %v\n", ev.TopicPartition.Error)
				} else {
					fmt.Printf("Successfully produced record to topic %s partition [%d] @ offset %v\n",
						*ev.TopicPartition.Topic, ev.TopicPartition.Partition, ev.TopicPartition.Offset)
				}
			}
		}
	}()

	// Produce a message to a topic
	topic := "reevu.test"
	message := &kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &topic, Partition: kafka.PartitionAny},
		Value:          []byte("Hello, Kafka!"),
	}

	// Produce the message
	if err := producer.Produce(message, nil); err != nil {
		panic(err)
	}

	// Wait for message deliveries before shutting down
	producer.Flush(15 * 1000)
	fmt.Println("Message sent successfully")
}
