from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.db.database import Base
from sqlalchemy.orm import relationship

class RouteStop(Base):
    __tablename__ = "route_stops"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    route_id = Column(UUID(as_uuid=True), ForeignKey("routes.id", ondelete="CASCADE"), nullable=False)
    stop_id = Column(UUID(as_uuid=True), ForeignKey("stops.id", ondelete="CASCADE"), nullable=False)
    sequence = Column(Integer, nullable=False)

    # Add this relationship
    stop = relationship("Stop", lazy="joined")

    __table_args__ = (
        UniqueConstraint("route_id", "sequence", name="uq_route_stops_route_sequence"),
        UniqueConstraint("route_id", "stop_id", name="uq_route_stops_route_stop"),
    )