from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from typing import Optional
from app.websockets.manager import connection_manager

router = APIRouter(prefix="/ws", tags=["WebSockets"])

@router.websocket("/tracking/{user_id}")
async def tracking_endpoint(websocket: WebSocket, user_id: str):
    """
    WebSocket endpoint for passengers to connect and track vehicles.
    They can send JSON messages to subscribe/unsubscribe to specific routes.
    """
    await connection_manager.connect(websocket, user_id)
    
    try:
        while True:
            # Wait for messages from the client (e.g. {"action": "subscribe", "route_id": "123"})
            data = await websocket.receive_json()
            
            action = data.get("action")
            route_id = data.get("route_id")
            
            if action == "subscribe" and route_id:
                await connection_manager.subscribe_to_route(websocket, route_id)
                await websocket.send_json({"status": "subscribed", "route_id": route_id})
                
            elif action == "unsubscribe" and route_id:
                await connection_manager.unsubscribe_from_route(websocket, route_id)
                await websocket.send_json({"status": "unsubscribed", "route_id": route_id})
                
    except WebSocketDisconnect:
        connection_manager.disconnect(websocket, user_id)
