# Redis Pub/Sub Quick Start Guide

## What is Redis Pub/Sub?

Redis Pub/Sub is a **lightweight messaging pattern** built into Redis, primarily known as an in-memory data store. It provides simple publish-subscribe messaging with extremely low latency.

### Key Concepts

- **Publisher**: Application that publishes messages to channels
- **Subscriber**: Application that listens to channels and receives messages
- **Channel**: Named message stream (e.g., "mychannel", "notifications", "events")
- **Pattern Subscription**: Subscribe to multiple channels using wildcards (e.g., "news.*")

### When to Use Redis Pub/Sub

✅ **Use Redis Pub/Sub for:**
- Simple pub/sub with minimal setup
- Real-time features (chat, notifications, live updates)
- Very low latency messaging (microseconds)
- Already using Redis for caching
- Fire-and-forget messaging (loss is acceptable)
- Low to medium message volume

❌ **Don't use Redis Pub/Sub for:**
- Guaranteed message delivery
- Message persistence (messages not saved to disk)
- Critical systems where loss is unacceptable
- Message acknowledgment requirements
- Message replay or history

## Architecture Overview

```
Publisher → Channel → Active Subscribers (only)
                       ↓
                  (messages not persisted)
```

**Key Characteristics:**
- **Fire-and-forget**: Messages only delivered to currently connected subscribers
- **No persistence**: Messages disappear if no one is listening
- **No acknowledgment**: No guarantee messages were received
- **Very fast**: In-memory delivery with microsecond latency
- **Simple**: No complex routing or message queues

## Setup Instructions

### 1. Start Redis with Docker Compose

```bash
# Navigate to the Redis directory
cd /path/to/kafka-test/redis

# Start Redis and RedisInsight (optional UI)
docker-compose up -d

# Verify services are running
docker-compose ps
```

You should see:
- `redis` - Running on port 6379
- `redis-insight` - Running on port 8001 (optional UI)

### 2. Access RedisInsight (Optional)

Open your browser and navigate to:
- **RedisInsight**: http://localhost:8001

This provides:
- Visual interface to Redis
- Command execution
- Real-time monitoring
- Key browser

**First time setup:**
1. Click "Add Redis Database"
2. Host: `redis` (or `localhost`)
3. Port: `6379`
4. Name: `local-redis`

## Running the Examples

### Terminal 1 - Start Subscriber

```bash
# Navigate to Redis directory
cd redis

# Run subscriber (it will wait for messages)
go run sub.go
```

**Output:**
```
Subscribed to channel: mychannel
Waiting for messages... (Press Ctrl+C to exit)
```

### Terminal 2 - Run Publisher

```bash
# In a new terminal, navigate to Redis directory
cd redis

# Run publisher (publishes messages every second)
go run pub.go
```

**Output (Publisher):**
```
Published: Message 1
Published: Message 2
Published: Message 3
...
```

**Output (Subscriber):**
```
Received message from channel mychannel: Message 1
Received message from channel mychannel: Message 2
Received message from channel mychannel: Message 3
...
```

**Note:** Publisher runs continuously. Press Ctrl+C to stop.

## Understanding the Code

### Publisher Code (pub.go)

```go
// 1. Create Redis client
client := redis.NewClient(&redis.Options{
    Addr: "localhost:6379",  // Redis server address
})

// 2. Publish messages to a channel
err := client.Publish(ctx, "mychannel", "Hello Redis!").Err()

// 3. Clean up
client.Close()
```

**Key Concepts:**
- **Context**: Use Go context for timeouts and cancellation
- **Channel Name**: Simple string identifier
- **Message**: Any string/byte data
- **No Guarantee**: Message may be lost if no subscribers

### Subscriber Code (sub.go)

```go
// 1. Create Redis client
client := redis.NewClient(&redis.Options{
    Addr: "localhost:6379",
})

// 2. Subscribe to channel(s)
pubsub := client.Subscribe(ctx, "mychannel")

// 3. Get channel for receiving messages
ch := pubsub.Channel()

// 4. Receive messages in a loop
for msg := range ch {
    fmt.Printf("Received: %s\n", msg.Payload)
}

// 5. Clean up
pubsub.Close()
client.Close()
```

**Key Concepts:**
- **PubSub Connection**: Special connection for subscriptions
- **Channel**: Go channel that receives messages
- **Blocking**: Waits for messages indefinitely
- **Pattern Matching**: Can subscribe to `news.*` to match `news.sports`, `news.tech`, etc.

## Common Operations

### Publish a Message

```bash
# Using redis-cli
docker exec -it redis redis-cli PUBLISH mychannel "Hello World"
```

### Subscribe to a Channel

```bash
# Using redis-cli
docker exec -it redis redis-cli SUBSCRIBE mychannel

# Press Ctrl+C to exit
```

### Subscribe with Pattern Matching

```bash
# Subscribe to all channels starting with "news"
docker exec -it redis redis-cli PSUBSCRIBE "news.*"
```

### Check Active Channels

```bash
# List all active channels
docker exec -it redis redis-cli PUBSUB CHANNELS

# Count subscribers on a channel
docker exec -it redis redis-cli PUBSUB NUMSUB mychannel
```

## Configuration

### Redis Client Configuration

```go
client := redis.NewClient(&redis.Options{
    Addr:         "localhost:6379",
    Password:     "",          // Set if auth enabled
    DB:           0,           // Database number
    DialTimeout:  5 * time.Second,
    ReadTimeout:  3 * time.Second,
    WriteTimeout: 3 * time.Second,
    PoolSize:     10,          // Connection pool size
})
```

### Environment-Based Configuration

```go
// Read from environment variables
redisAddr := os.Getenv("REDIS_ADDR")
if redisAddr == "" {
    redisAddr = "localhost:6379"
}

client := redis.NewClient(&redis.Options{
    Addr: redisAddr,
})
```

## Troubleshooting

### Issue: Subscriber not receiving messages

**Symptoms:** Publisher runs but subscriber shows nothing

**Solutions:**
1. **Start subscriber FIRST** (messages not persisted!)
2. Verify channel name matches exactly
3. Check Redis is running: `docker-compose ps`
4. Test with redis-cli:
   ```bash
   # Terminal 1
   docker exec -it redis redis-cli SUBSCRIBE mychannel

   # Terminal 2
   docker exec -it redis redis-cli PUBLISH mychannel "test"
   ```

### Issue: Cannot connect to Redis

**Error:** `dial tcp [::1]:6379: connect: connection refused`

**Solutions:**
```bash
# Verify Redis is running
docker-compose ps

# Check Redis logs
docker-compose logs redis

# Test connection
docker exec -it redis redis-cli ping
# Should return: PONG
```

### Issue: Messages being lost

**This is expected behavior!**

Redis Pub/Sub is fire-and-forget:
- Messages sent when no subscribers = lost forever
- Subscriber disconnects = misses messages during downtime
- No message queue or persistence

**Alternative:** Use Redis Streams for persistent messaging:
```go
// Redis Streams (alternative to Pub/Sub)
client.XAdd(ctx, &redis.XAddArgs{
    Stream: "mystream",
    Values: map[string]interface{}{"message": "Hello"},
})
```

### Issue: Port 6379 already in use

**Solutions:**
```bash
# Find what's using the port
lsof -i :6379

# Stop existing Redis
docker-compose down

# Or change port in docker-compose.yml
```

## Advanced Features

### Pattern Subscriptions

Subscribe to multiple channels with wildcards:

```go
// Subscribe to news.*, sports.*, tech.*
pubsub := client.PSubscribe(ctx, "news.*", "sports.*", "tech.*")

for msg := range pubsub.Channel() {
    fmt.Printf("Channel: %s, Message: %s\n",
        msg.Channel, msg.Payload)
}
```

### Multiple Channels

Subscribe to multiple specific channels:

```go
pubsub := client.Subscribe(ctx, "channel1", "channel2", "channel3")

for msg := range pubsub.Channel() {
    switch msg.Channel {
    case "channel1":
        handleChannel1(msg.Payload)
    case "channel2":
        handleChannel2(msg.Payload)
    }
}
```

### Graceful Shutdown

Handle shutdown signals properly:

```go
// Set up signal handling
sigChan := make(chan os.Signal, 1)
signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

go func() {
    <-sigChan
    fmt.Println("\nShutting down...")
    pubsub.Close()
    client.Close()
    os.Exit(0)
}()
```

## Redis Pub/Sub vs Redis Streams

| Feature | Pub/Sub | Streams |
|---------|---------|---------|
| **Persistence** | No | Yes |
| **Message History** | No | Yes |
| **Consumer Groups** | No | Yes |
| **Delivery Guarantee** | None | At-least-once |
| **Latency** | Lower | Slightly higher |
| **Use Case** | Real-time ephemeral | Persistent messaging |

**When to use Streams instead:**
- Need message persistence
- Want message history/replay
- Need acknowledgments
- Building critical systems

## Performance Tips

### For Publishers:
- **Connection pooling**: Reuse Redis client
- **Pipeline**: Batch multiple PUBLISH commands
- **Fire-and-forget**: Don't wait for responses in hot paths

### For Subscribers:
- **Fast handlers**: Process messages quickly
- **Goroutines**: Handle messages concurrently
- **Pattern matching**: Use wisely (has overhead)

### General:
- **Network**: Use local Redis or same datacenter
- **Connection limits**: Monitor and tune `maxclients`
- **Keep-alive**: Configure TCP keep-alive for long connections

## Real-World Use Cases

### Chat Application

```go
// Publisher (user sends message)
client.Publish(ctx, "chat:room123", userMessage)

// Subscriber (all users in room receive)
pubsub := client.Subscribe(ctx, "chat:room123")
```

### Live Dashboard Updates

```go
// Publisher (metrics collector)
client.Publish(ctx, "metrics:realtime", metricsJSON)

// Subscriber (dashboard)
pubsub := client.Subscribe(ctx, "metrics:realtime")
```

### Notification System

```go
// Publisher (notification service)
client.Publish(ctx, fmt.Sprintf("notifications:user:%s", userID), notification)

// Subscriber (user's connected client)
pubsub := client.Subscribe(ctx, fmt.Sprintf("notifications:user:%s", userID))
```

## Comparison with Other Systems

**Redis vs Kafka:**
- ✅ Redis: Much simpler, lower latency
- ❌ Redis: No persistence, no replay
- ✅ Kafka: Persistent, can replay messages
- ❌ Kafka: More complex, higher latency

**Redis vs RabbitMQ:**
- ✅ Redis: Simpler, faster for simple pub/sub
- ❌ Redis: No guarantees, no persistence
- ✅ RabbitMQ: Reliable, guaranteed delivery
- ❌ RabbitMQ: More complex setup

## Next Steps

1. **Experiment**: Try pattern subscriptions with wildcards
2. **Multiple Subscribers**: Run multiple subscribers on same channel
3. **Redis Streams**: Explore persistent alternative
4. **Integration**: Combine with Redis cache for fast data+messaging
5. **Compare**: Read [COMPARISON.md](../COMPARISON.md) for other options

## Additional Resources

- [Redis Pub/Sub Documentation](https://redis.io/docs/manual/pubsub/)
- [go-redis Library](https://github.com/go-redis/redis)
- [Redis Streams](https://redis.io/docs/data-types/streams/)
- [Redis Best Practices](https://redis.io/docs/manual/patterns/)

---

**Perfect for real-time!** Redis Pub/Sub is the simplest way to add real-time messaging to your application.
