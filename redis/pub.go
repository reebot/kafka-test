package main

import (
	"context"
	"time"

	"github.com/go-redis/redis/v8"
)

var ctx = context.Background()

func main() {
	rdb := redis.NewClient(&redis.Options{
		Addr: "localhost:6379", // or your Redis server address
	})

	for {
		err := rdb.Publish(ctx, "mychannel", "Hello, Redis!").Err()
		if err != nil {
			panic(err)
		}
		time.Sleep(1 * time.Second)
	}
}
