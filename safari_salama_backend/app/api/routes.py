from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List
from app.db.database import get_db
from app.models.route import Route
from app.models.stop import Stop
from app.models.route_stop import RouteStop
from app.schemas.route import RouteCreate, RouteResponse

router = APIRouter(prefix="/api/routes", tags=["routes"])


@router.get("", response_model=List[RouteResponse])
def get_routes(
    active_only: bool = True,
    db: Session = Depends(get_db)
):
    query = db.query(Route).options(
        joinedload(Route.route_stops).joinedload(RouteStop.stop)
    )

    if active_only:
        query = query.filter(Route.is_active == True)

    routes = query.order_by(Route.route_number).all()
    return routes


@router.get("/{route_id}", response_model=RouteResponse)
def get_route(route_id: str, db: Session = Depends(get_db)):
    route = (
        db.query(Route)
        .options(joinedload(Route.route_stops).joinedload(RouteStop.stop))
        .filter(Route.id == route_id, Route.is_active == True)
        .first()
    )
    if not route:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Route not found"
        )
    return route


@router.post("", response_model=RouteResponse, status_code=status.HTTP_201_CREATED)
def create_route(route: RouteCreate, db: Session = Depends(get_db)):
    payload = route.model_dump(exclude={"stops"})
    new_route = Route(**payload)

    db.add(new_route)
    db.flush()  # get new_route.id before committing

    stops = route.stops or []
    for idx, stop_name in enumerate(stops):
        clean = stop_name.strip()
        if not clean:
            continue

        # case-insensitive match so "CBD" and "cbd" do not create duplicates
        stop = db.query(Stop).filter(Stop.name.ilike(clean)).first()
        if not stop:
            stop = Stop(name=clean)
            db.add(stop)
            db.flush()

        db.add(RouteStop(route_id=new_route.id, stop_id=stop.id, sequence=idx))

    db.commit()

    # reload with stops to match response_model
    new_route = (
        db.query(Route)
        .options(joinedload(Route.route_stops).joinedload(RouteStop.stop))
        .filter(Route.id == new_route.id)
        .first()
    )
    return new_route
