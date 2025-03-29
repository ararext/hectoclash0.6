package main

import (
	"fmt"
	"log"
	"net/http"
	"github.com/gorilla/websocket"
	"math/rand"
)

// WebSocket upgrader
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

// Client structure
type Client struct {
	conn *websocket.Conn
}

// Clients and message channel
var clients = make(map[*Client]bool)
var broadcast = make(chan string)

// Handle WebSocket connections
func handleConnections(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Error upgrading connection:", err)
		return
	}
	defer conn.Close()

	client := &Client{conn: conn}
	clients[client] = true

	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			log.Println("Client disconnected:", err)
			delete(clients, client)
			break
		}
		log.Println("Received message:", string(msg))
		broadcast <- string(msg)
	}
}

// Handle incoming messages
func handleMessages() {
	for {
		msg := <-broadcast
		for client := range clients {
			err := client.conn.WriteMessage(websocket.TextMessage, []byte(msg))
			if err != nil {
				log.Println("Error sending message:", err)
				client.conn.Close()
				delete(clients, client)
			}
		}
	}
}

// Generate a random puzzle (6-digit number)
func generatePuzzle() string {
	puzzle := ""
	for i := 0; i < 6; i++ {
		puzzle += fmt.Sprintf("%d", rand.Intn(9)+1)
	}
	return puzzle
}

// API handler for puzzles
func puzzleHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, generatePuzzle())
}

// Start the server
func main() {
	http.HandleFunc("/ws", handleConnections)  // WebSocket endpoint
	http.HandleFunc("/puzzle", puzzleHandler)  // Puzzle generation endpoint
	go handleMessages()                        // Start WebSocket message handling

	log.Println("Server started on :8080")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		log.Fatal("Error starting server:", err)
	}
}
