import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from auth import User, get_current_user
from database import get_db
from models import (
    Asset,
    AssetCreate,
    AssetOut,
    ContributionCreate,
    ContributionOut,
    ContributionRecord,
    Household,
)

router = APIRouter()


async def _owned_asset(asset_id: uuid.UUID, user: User, db: AsyncSession) -> Asset:
    result = await db.execute(
        select(Asset)
        .where(Asset.id == asset_id)
        .join(Household)
        .where(Household.owner_id == user.id)
    )
    asset = result.scalar_one_or_none()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found")
    return asset


@router.post("", response_model=AssetOut, status_code=201)
async def create_asset(
    body: AssetCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Household).where(
            Household.id == body.household_id,
            Household.owner_id == current_user.id,
        )
    )
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Household not found")
    data = body.model_dump()
    data["purchase_date"] = data.get("purchase_date") or datetime.utcnow()
    asset = Asset(**data)
    db.add(asset)
    await db.commit()
    await db.refresh(asset)
    return asset


@router.put("/{asset_id}", response_model=AssetOut)
async def update_asset(
    asset_id: uuid.UUID,
    body: AssetCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    asset = await _owned_asset(asset_id, current_user, db)
    for k, v in body.model_dump().items():
        if v is not None or k != "purchase_date":
            setattr(asset, k, v)
    await db.commit()
    await db.refresh(asset)
    return asset


@router.delete("/{asset_id}", status_code=204)
async def delete_asset(
    asset_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    asset = await _owned_asset(asset_id, current_user, db)
    await db.delete(asset)
    await db.commit()


@router.get("/{asset_id}/contributions", response_model=list[ContributionOut])
async def list_contributions(
    asset_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _owned_asset(asset_id, current_user, db)
    result = await db.execute(
        select(ContributionRecord).where(ContributionRecord.asset_id == asset_id)
    )
    return result.scalars().all()


@router.post("/{asset_id}/contributions", response_model=ContributionOut, status_code=201)
async def add_contribution(
    asset_id: uuid.UUID,
    body: ContributionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _owned_asset(asset_id, current_user, db)
    c = ContributionRecord(**body.model_dump())
    db.add(c)
    await db.commit()
    await db.refresh(c)
    return c


@router.delete("/{asset_id}/contributions/{contribution_id}", status_code=204)
async def delete_contribution(
    asset_id: uuid.UUID,
    contribution_id: uuid.UUID,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await _owned_asset(asset_id, current_user, db)
    result = await db.execute(
        select(ContributionRecord).where(
            ContributionRecord.id == contribution_id,
            ContributionRecord.asset_id == asset_id,
        )
    )
    c = result.scalar_one_or_none()
    if not c:
        raise HTTPException(status_code=404, detail="Contribution not found")
    await db.delete(c)
    await db.commit()
