# Contributing to Message Queue Systems Examples

Thank you for your interest in contributing to this educational project! This guide will help you get started.

## 🎯 Project Goals

This repository is an **educational resource** for developers learning about message queue systems. All contributions should prioritize:

1. **Clarity**: Code and documentation should be easy for beginners to understand
2. **Accuracy**: Examples should follow best practices and be technically correct
3. **Completeness**: Each message queue system should have comprehensive coverage
4. **Consistency**: Similar structure and patterns across all examples

## 🤝 Ways to Contribute

### 1. Add a New Message Queue System

Want to add NATS, Amazon SQS, Google Pub/Sub, or another system? Great!

**Requirements:**
- Producer and consumer examples in Go
- Docker Compose setup for local development
- Comprehensive guide following existing format (see `KAFKA_GUIDE.md`)
- Educational code comments explaining key concepts
- Update main README.md and COMPARISON.md

**Structure:**
```
new-system/
├── producer.go
├── consumer.go
├── docker-compose.yml
└── guide.md
```

### 2. Improve Documentation

- Fix typos or unclear explanations
- Add diagrams or visualizations
- Expand troubleshooting sections
- Add real-world use case examples
- Improve code comments

### 3. Enhance Code Examples

- Add error handling patterns
- Show retry logic implementations
- Demonstrate advanced features
- Add configuration examples
- Improve educational comments

### 4. Add Testing

Currently, this repository lacks tests. Contributions welcome for:
- Integration tests using test containers
- Example validation scripts
- CI/CD pipeline setup

### 5. Create Benchmarks

Help beginners understand performance by adding:
- Throughput comparisons
- Latency measurements
- Resource usage metrics
- Scalability tests

## 📋 Contribution Process

### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Clone your fork
git clone https://github.com/YOUR-USERNAME/kafka-test.git
cd kafka-test

# Add upstream remote
git remote add upstream https://github.com/ORIGINAL-OWNER/kafka-test.git
```

### 2. Create a Branch

```bash
# Create a descriptive branch name
git checkout -b add-nats-examples
# or
git checkout -b improve-kafka-docs
# or
git checkout -b fix-rabbitmq-typos
```

### 3. Make Your Changes

Follow these guidelines:

#### Code Style
- **Go code**: Follow standard Go formatting (`gofmt`)
- **Comments**: Explain the "why", not just the "what"
- **Educational focus**: Add comments that help beginners learn
- **Error handling**: Show proper error handling patterns
- **Keep it simple**: Avoid over-engineering; clarity over cleverness

#### Documentation Style
- **Clear headings**: Use descriptive section titles
- **Examples**: Include code snippets and expected output
- **Beginner-friendly**: Explain concepts, don't assume knowledge
- **Consistent format**: Match the style of existing guides
- **No jargon**: Explain technical terms when first used

#### Commit Messages
```
# Good commit messages
Add NSQ message queue examples with guide
Fix typo in RabbitMQ connection string
Improve Kafka error handling in consumer

# Bad commit messages
Update files
Fix stuff
WIP
```

### 4. Test Your Changes

Before submitting, verify:

- [ ] Docker Compose files start successfully
- [ ] Producer sends messages without errors
- [ ] Consumer receives messages correctly
- [ ] All links in documentation work
- [ ] Code examples are copy-pasteable
- [ ] Guide matches the format of existing guides
- [ ] No sensitive information (passwords, keys) committed

```bash
# Test Docker Compose
cd your-system
docker-compose up -d
docker-compose ps
docker-compose logs

# Test code examples
go run producer.go
go run consumer.go

# Clean up
docker-compose down
```

### 5. Submit a Pull Request

```bash
# Update your fork
git fetch upstream
git rebase upstream/main

# Push your changes
git push origin your-branch-name
```

Then open a Pull Request on GitHub with:

- **Clear title**: "Add NATS examples" or "Fix Kafka documentation typos"
- **Description**: Explain what you changed and why
- **Testing notes**: How you tested your changes
- **Screenshots**: If relevant (UI changes, output examples)

## ✅ Code Review Process

Maintainers will review your PR for:

1. **Educational value**: Does it help beginners learn?
2. **Accuracy**: Is it technically correct?
3. **Completeness**: Is all necessary documentation included?
4. **Consistency**: Does it match existing patterns?
5. **Testing**: Does it work as described?

Expect feedback and be open to suggestions!

## 📏 Specific Guidelines

### Adding a New Message Queue System

Follow this checklist:

- [ ] Create directory: `system-name/`
- [ ] Add `producer.go` with educational comments
- [ ] Add `consumer.go` with educational comments
- [ ] Create `docker-compose.yml` for local setup
- [ ] Write comprehensive `guide.md` (use `KAFKA_GUIDE.md` as template)
- [ ] Update main `README.md`:
  - Add to comparison table
  - Add to directory structure
  - Add to system-specific guides list
  - Update quick start if needed
- [ ] Update `COMPARISON.md`:
  - Add row to comparison table
  - Add "When to Use X" section
  - Add to decision tree
  - Add performance characteristics
- [ ] Update `Makefile` with new targets
- [ ] Test everything works end-to-end

### Writing Guides

Each guide should include:

1. **What is X?** - High-level explanation
2. **Key Concepts** - Terminology explained
3. **When to Use X** - Use cases (✅ and ❌)
4. **Architecture Overview** - Simple diagram or description
5. **Setup Instructions** - Docker Compose commands
6. **Running Examples** - Step-by-step with expected output
7. **Understanding the Code** - Code walkthroughs with comments
8. **Common Operations** - CLI commands for management
9. **Configuration** - How to configure the client
10. **Troubleshooting** - Common issues and solutions
11. **Advanced Features** - Optional deeper dives
12. **Performance Tips** - Best practices
13. **Comparison** - vs other systems
14. **Next Steps** - What to learn next
15. **Resources** - Links to official docs

### Code Comments

Educational comments should:

```go
// ❌ Bad: States the obvious
i := 0  // Set i to 0

// ✅ Good: Explains the concept
// Kafka uses message keys for partitioning - messages with the
// same key always go to the same partition, preserving order
key := []byte(userName)
```

## 🐛 Reporting Issues

Found a bug or have a suggestion?

**For bugs:**
- Describe what you expected to happen
- Describe what actually happened
- Include error messages and logs
- Mention your environment (OS, Go version, Docker version)
- Steps to reproduce

**For enhancements:**
- Describe the improvement clearly
- Explain why it would help beginners
- Suggest implementation if you have ideas

## 💬 Questions?

- Open an issue with the "question" label
- Be specific about what you're trying to understand
- Include context (what you've tried, what didn't work)

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

## 🙏 Thank You!

Every contribution, no matter how small, helps make this resource better for developers learning about message queues. We appreciate your time and effort!

---

**Happy Contributing!** 🚀
