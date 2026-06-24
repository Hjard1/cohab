import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import User, get_current_user
from database import get_db
from models import (
    ExpenseCreate,
    ExpenseOut,
    Household,
    HouseholdCreate,
    HouseholdOut,
    SharedExpense,
)

router = APIRouter()


async def _owned_household(
    household_id: uuid.UUID, user: User, db: AsyncSession
) -> Household:
    result = await db.execute(
        select(Household).where(
            Household.id == household_id, Household.owner_id == user.id
        )
    )
    h = result.scalar_one_or_none()
    if not h:
        raise HTTPException(status_code=404, detail="Household not found")
    return h


@router.get("/me", response_model=HouseholdOut)
async def get_my_household(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Household).where(Household.owner_id == current_user.id)
    )
    h = result.scalar_one_or_none()
    if not h:
        raise HTTPException(status_code=404, detail="No household found")
    return h


@router.post("", response_model=HouseholdOut, status_code=201)
async def create_household(
    body: HouseholdCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    existing = await db.execute(
        select(Household).where(Household.owner_id == current_user.id)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Household already exists")
    h = Household(**body.model_dump(), owner_id=current_user.id)
    db.add(h)
    await db.commit()
    await db.refresh(h)
    return h


@router.put("/{household_id}", response_model=HouseholdOut)
async def update_household(
    household_id: uuid.UUID,
    body: HouseholdCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    h = await _owned_household(household_id, current_user, db)
    for k, v in body.model_dump().items():
        setattr(h, k, v)
    await db.commit()
    await db.refresh(h)
    return h


@router.get("/{household_id}/expenses", response_model=list[ExpenseOut])
async def list_expenses(
    household_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _owned_household(household_id, current_user, db)
    result = await db.execute(
        select(SharedExpense).where(SharedExpense.household_id == household_id)
    )
    return result.scalars().all()


@router.post("/{household_id}/expenses", response_model=ExpenseOut, status_code=201)
async def add_expense(
    household_id: uuid.UUID,
    body: ExpenseCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _owned_household(household_id, current_user, db)
    data = body.model_dump()
    data["date"] = data.get("date") or datetime.utcnow()
    expense = SharedExpense(household_id=household_id, **data)
    db.add(expense)
    await db.commit()
    await db.refresh(expense)
    return expense
