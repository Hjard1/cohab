import uuid
from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


# ── ORM models ────────────────────────────────────────────────────────────────

class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String, unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    households: Mapped[list["Household"]] = relationship(
        back_populates="owner", cascade="all, delete-orphan"
    )


class Household(Base):
    __tablename__ = "households"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    owner_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id"))
    partner_a_name: Mapped[str] = mapped_column(String)
    partner_b_name: Mapped[str] = mapped_column(String)
    currency: Mapped[str] = mapped_column(String, default="GBP")
    annual_interest_rate: Mapped[float] = mapped_column(Float, default=0.05)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    owner: Mapped["User"] = relationship(back_populates="households")
    assets: Mapped[list["Asset"]] = relationship(
        back_populates="household", cascade="all, delete-orphan"
    )
    expenses: Mapped[list["SharedExpense"]] = relationship(
        back_populates="household", cascade="all, delete-orphan"
    )


class Asset(Base):
    __tablename__ = "assets"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    household_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("households.id"))
    label: Mapped[str] = mapped_column(String)
    address: Mapped[str] = mapped_column(String, default="")
    current_value: Mapped[float] = mapped_column(Float)
    remaining_loan: Mapped[float] = mapped_column(Float, default=0.0)
    sales_cost_fraction: Mapped[float] = mapped_column(Float, default=0.02)
    ownership_share_a: Mapped[float] = mapped_column(Float, default=0.5)
    purchase_date: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    household: Mapped["Household"] = relationship(back_populates="assets")
    contributions: Mapped[list["ContributionRecord"]] = relationship(
        back_populates="asset", cascade="all, delete-orphan"
    )


class ContributionRecord(Base):
    __tablename__ = "contributions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    asset_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("assets.id"))
    owner_key: Mapped[str] = mapped_column(String)  # "A" or "B"
    amount: Mapped[float] = mapped_column(Float)
    date: Mapped[datetime] = mapped_column(DateTime)
    label: Mapped[str] = mapped_column(String)
    category: Mapped[str] = mapped_column(String, default="other")

    asset: Mapped["Asset"] = relationship(back_populates="contributions")


class SharedExpense(Base):
    __tablename__ = "shared_expenses"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    household_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("households.id"))
    label: Mapped[str] = mapped_column(String)
    amount: Mapped[float] = mapped_column(Float)
    paid_by_key: Mapped[str] = mapped_column(String)  # "A" or "B"
    split_ratio_a: Mapped[float] = mapped_column(Float, default=0.5)
    date: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    category: Mapped[str] = mapped_column(String, default="other")
    is_recurring: Mapped[bool] = mapped_column(Boolean, default=False)

    household: Mapped["Household"] = relationship(back_populates="expenses")


# ── Pydantic schemas ──────────────────────────────────────────────────────────

class UserCreate(BaseModel):
    email: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class HouseholdCreate(BaseModel):
    partner_a_name: str
    partner_b_name: str
    currency: str = "GBP"
    annual_interest_rate: float = 0.05


class HouseholdOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    partner_a_name: str
    partner_b_name: str
    currency: str
    annual_interest_rate: float
    created_at: datetime


class AssetCreate(BaseModel):
    household_id: uuid.UUID
    label: str
    address: str = ""
    current_value: float
    remaining_loan: float = 0.0
    sales_cost_fraction: float = 0.02
    ownership_share_a: float = 0.5
    purchase_date: Optional[datetime] = None


class AssetOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    household_id: uuid.UUID
    label: str
    address: str
    current_value: float
    remaining_loan: float
    sales_cost_fraction: float
    ownership_share_a: float
    purchase_date: datetime


class ContributionCreate(BaseModel):
    asset_id: uuid.UUID
    owner_key: str
    amount: float
    date: datetime
    label: str
    category: str = "other"


class ContributionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    asset_id: uuid.UUID
    owner_key: str
    amount: float
    date: datetime
    label: str
    category: str


class ExpenseCreate(BaseModel):
    label: str
    amount: float
    paid_by_key: str
    split_ratio_a: float = 0.5
    date: Optional[datetime] = None
    category: str = "other"
    is_recurring: bool = False


class ExpenseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    household_id: uuid.UUID
    label: str
    amount: float
    paid_by_key: str
    split_ratio_a: float
    date: datetime
    category: str
    is_recurring: bool


# ── DocuSeal submission tracking ──────────────────────────────────────────────
# Tracks every submission cohab creates so the webhook can verify ownership
# and ignore events that belong to other apps (e.g. Samboappen) on the
# same DocuSeal account.

class DocuSealSubmissionRecord(Base):
    __tablename__ = "cohab_docuseal_submissions"

    id: Mapped[uuid.UUID] = mapped_column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    household_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("households.id"))
    submission_id: Mapped[str] = mapped_column(String, index=True)   # DocuSeal numeric id
    slug: Mapped[str] = mapped_column(String, unique=True, index=True)
    status: Mapped[str] = mapped_column(String, default="pending")   # pending|completed|declined
    email_a: Mapped[str] = mapped_column(String)
    email_b: Mapped[str] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)


class DocuSealSubmissionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: uuid.UUID
    household_id: uuid.UUID
    submission_id: str
    slug: str
    status: str
    created_at: datetime
    completed_at: Optional[datetime]
