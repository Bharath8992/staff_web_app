from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.future import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import or_, func
from typing import List, Optional
from pydantic import BaseModel
from sqlalchemy import asc, desc

from database import SessionLocal, engine, Base
from models import Staff
from sqlalchemy import select, or_, asc, desc, text


app = FastAPI()

# CORS setup
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all for development
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Auto-create tables
@app.on_event("startup")
async def startup():
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# Pydantic Schema
class StaffSchema(BaseModel):
    id: Optional[int] = None
    first_name: str
    last_name: str
    gender: str
    dob: str
    email: str
    job_title: str
    department: str
    duty_station: str

    class Config:
        orm_mode = True


async def get_db():
    async with SessionLocal() as session:
        yield session
        
        
@app.get("/staff", response_model=List[StaffSchema])
async def get_staffs(
    page: int = 1,
    page_size: int = 10,
    search: str = "",
    sort_by: str = "id",
    sort_order: str = "asc",
    db: AsyncSession = Depends(get_db)
):
    offset = (page - 1) * page_size
    stmt = select(Staff)

    if search:
        search_term = f"%{search.lower()}%"
        stmt = stmt.filter(
            or_(
                Staff.first_name.ilike(search_term),
                Staff.last_name.ilike(search_term),
                Staff.gender.ilike(search_term),
                Staff.dob.ilike(search_term),
                Staff.email.ilike(search_term),
                Staff.job_title.ilike(search_term),
                Staff.department.ilike(search_term),
                Staff.duty_station.ilike(search_term),
            )
        )

    allowed_sort_fields = {
        "id": Staff.id,
        "first_name": Staff.first_name,
        "last_name": Staff.last_name,
        "gender": Staff.gender,
        "dob": Staff.dob,
        "email": Staff.email,
        "job_title": Staff.job_title,
        "department": Staff.department,
        "duty_station": Staff.duty_station
    }

    sort_column = allowed_sort_fields.get(sort_by, Staff.id)
    order = asc(sort_column) if sort_order.lower() == "asc" else desc(sort_column)

    stmt = stmt.order_by(order).offset(offset).limit(page_size)
    result = await db.execute(stmt)
    return result.scalars().all()


@app.post("/staff", response_model=StaffSchema)
async def create_staff(staff: StaffSchema, db: AsyncSession = Depends(get_db)):
    new_staff = Staff(**staff.dict(exclude_unset=True))
    db.add(new_staff)
    await db.commit()
    await db.refresh(new_staff)
    return new_staff


@app.put("/staff/{staff_id}", response_model=StaffSchema)
async def update_staff(staff_id: int, staff: StaffSchema, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Staff).filter(Staff.id == staff_id))
    db_staff = result.scalar_one_or_none()
    if db_staff is None:
        raise HTTPException(status_code=404, detail="Staff not found")
    for key, value in staff.dict(exclude_unset=True).items():
        setattr(db_staff, key, value)
    await db.commit()
    await db.refresh(db_staff)
    return db_staff


@app.delete("/staff/{staff_id}")
async def delete_staff(staff_id: int, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Staff).filter(Staff.id == staff_id))
    db_staff = result.scalar_one_or_none()
    if db_staff is None:
        raise HTTPException(status_code=404, detail="Staff not found")
    await db.delete(db_staff)
    await db.commit()
    return {"message": "Staff deleted"}
