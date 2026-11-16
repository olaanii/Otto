package server

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
)

// SSEEvent represents a Server-Sent Event payload.
type SSEEvent struct {
	Type      string `json:"type"`      // "file_changed", "git_operation", "agent_prompt", "stack_updated"
	Timestamp int64  `json:"timestamp"` // Unix timestamp in ms
	Data      any    `json:"data"`
}

// EventBroker manages active SSE subscribers and broadcasts real-time events.
type EventBroker struct {
	mu          sync.RWMutex
	subscribers map[chan SSEEvent]bool
	register    chan chan SSEEvent
	unregister  chan chan SSEEvent
	broadcast   chan SSEEvent
	stopCh      chan struct{}
}

// NewEventBroker initializes an EventBroker.
func NewEventBroker() *EventBroker {
	b := &EventBroker{
		subscribers: make(map[chan SSEEvent]bool),
		register:    make(chan chan SSEEvent),
		unregister:  make(chan chan SSEEvent),
		broadcast:   make(chan SSEEvent, 256),
		stopCh:      make(chan struct{}),
	}
	go b.run()
	return b
}

func (b *EventBroker) run() {
	for {
		select {
		case <-b.stopCh:
			b.mu.Lock()
			for ch := range b.subscribers {
				close(ch)
				delete(b.subscribers, ch)
			}
			b.mu.Unlock()
			return

		case ch := <-b.register:
			b.mu.Lock()
			b.subscribers[ch] = true
			b.mu.Unlock()

		case ch := <-b.unregister:
			b.mu.Lock()
			if _, ok := b.subscribers[ch]; ok {
				delete(b.subscribers, ch)
				close(ch)
			}
			b.mu.Unlock()

		case event := <-b.broadcast:
			b.mu.RLock()
			for ch := range b.subscribers {
				select {
				case ch <- event:
				default:
					// Drop if slow client buffer is full
				}
			}
			b.mu.RUnlock()
		}
	}
}

// Broadcast sends an event to all connected SSE clients.
func (b *EventBroker) Broadcast(eventType string, data any) {
	event := SSEEvent{
		Type:      eventType,
		Timestamp: time.Now().UnixMilli(),
		Data:      data,
	}

	select {
	case b.broadcast <- event:
	default:
	}
}

// Close gracefully stops the event broker.
func (b *EventBroker) Close() {
	close(b.stopCh)
}

// HandleEvents serves the GET /api/events SSE stream.
func (b *EventBroker) HandleEvents(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming unsupported", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("Access-Control-Allow-Origin", "*")

	clientChan := make(chan SSEEvent, 32)
	b.register <- clientChan

	defer func() {
		b.unregister <- clientChan
	}()

	// Initial connection acknowledgement
	initEvent := SSEEvent{
		Type:      "connected",
		Timestamp: time.Now().UnixMilli(),
		Data:      map[string]string{"status": "listening", "broker": "otto-daemon-sse"},
	}
	initBytes, _ := json.Marshal(initEvent)
	fmt.Fprintf(w, "event: %s\ndata: %s\n\n", initEvent.Type, string(initBytes))
	flusher.Flush()

	heartbeat := time.NewTicker(15 * time.Second)
	defer heartbeat.Stop()

	for {
		select {
		case <-r.Context().Done():
			return

		case <-heartbeat.C:
			fmt.Fprintf(w, ": keepalive\n\n")
			flusher.Flush()

		case event, ok := <-clientChan:
			if !ok {
				return
			}
			dataBytes, err := json.Marshal(event)
			if err != nil {
				continue
			}
			fmt.Fprintf(w, "event: %s\ndata: %s\n\n", event.Type, string(dataBytes))
			flusher.Flush()
		}
	}
}
