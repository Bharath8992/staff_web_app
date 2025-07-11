from sqlalchemy import Column, Integer, String
from database import Base


class Staff(Base):
    __tablename__ = "staff"

    id = Column(Integer, primary_key=True, index=True)
    first_name = Column(String)
    last_name = Column(String)
    gender = Column(String)
    dob = Column(String)
    email = Column(String)
    job_title = Column(String)
    department = Column(String)
    duty_station = Column(String)
