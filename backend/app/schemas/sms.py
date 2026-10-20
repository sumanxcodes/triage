from enum import Enum
from typing import Optional
from pydantic import BaseModel, Field


class FilterAction(str, Enum):
    NONE = "none"
    FILTER = "filter"
    JUNK = "junk"
    PROMOTION = "promotion"
    TRANSACTION = "transaction"


class AppleMessageFilterRequest(BaseModel):
    sender: Optional[str] = Field(default=None, description="Raw sender phone number or alphanumeric ID")
    messageBody: Optional[str] = Field(default=None, description="Raw text of the SMS message")


class AppleMessageFilterResponse(BaseModel):
    action: FilterAction = Field(default=FilterAction.NONE, description="IdentityLookup action to take")
    subAction: Optional[str] = Field(default=None, description="Optional sub-action category")
