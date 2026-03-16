from fastapi import WebSocket
from typing import Dict, Set, Any
import json
import logging

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        # Dictionary mapping route_id to a set of active connections (passengers watching the route)
        self.route_connections: Dict[str, Set[WebSocket]] = {}
        # Dictionary mapping user_id to their active websocket connection
        self.user_connections: Dict[str, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.user_connections[user_id] = websocket
        logger.info(f"User {user_id} connected to WebSocket")

    def disconnect(self, websocket: WebSocket, user_id: str):
        if user_id in self.user_connections:
            del self.user_connections[user_id]
        
        # Remove from any routes they are subscribed to
        for route_id, connections in self.route_connections.items():
            if websocket in connections:
                connections.remove(websocket)
                
        logger.info(f"User {user_id} disconnected from WebSocket")

    async def subscribe_to_route(self, websocket: WebSocket, route_id: str):
        if route_id not in self.route_connections:
            self.route_connections[route_id] = set()
        self.route_connections[route_id].add(websocket)
        logger.info(f"WebSocket subscribed to route {route_id}")

    async def unsubscribe_from_route(self, websocket: WebSocket, route_id: str):
        if route_id in self.route_connections and websocket in self.route_connections[route_id]:
            self.route_connections[route_id].remove(websocket)
            if not self.route_connections[route_id]:
                del self.route_connections[route_id]
            logger.info(f"WebSocket unsubscribed from route {route_id}")

    async def broadcast_vehicle_location(self, route_id: str, vehicle_data: dict):
        """
        Broadcasts a vehicle's updated location to all passengers subscribed to that route.
        """
        if route_id in self.route_connections:
            message = {
                "type": "vehicle_location_update",
                "data": vehicle_data
            }
            dead_connections = set()
            for connection in self.route_connections[route_id]:
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending message to connection: {e}")
                    dead_connections.add(connection)
            
            # Cleanup dead connections
            for dead in dead_connections:
                self.route_connections[route_id].remove(dead)

# Global connection manager instance
connection_manager = ConnectionManager()
