from typing import AsyncGenerator, List, Optional, Dict
from openai import AsyncOpenAI
import json

from ..core.config import get_settings
from ..models.schemas import UserPreferences, Fact, ThreadSummary
from .persona_prompts import build_full_system_prompt


class LLMService:
    """Service for interacting with OpenAI LLM."""
    
    def __init__(self):
        settings = get_settings()
        self.client = AsyncOpenAI(api_key=settings.openai_api_key)
        self.model = settings.openai_model
        self.vision_model = settings.openai_vision_model
    
    def _build_system_prompt(
        self,
        user_name: str,
        user_gender: Optional[str],
        preferences: UserPreferences,
        facts: List[Fact],
        summary: Optional[ThreadSummary],
    ) -> str:
        """Build the system prompt based on persona and user preferences."""
        
        # Convert facts to dict format
        facts_list = [{"key": f.key, "value": f.value, "status": f.status} for f in facts]
        
        # Convert summary to dict if exists
        summary_dict = None
        if summary:
            summary_dict = {"text": summary.text}
        
        # Convert preferences to dict
        prefs_dict = {
            "emojiLevel": preferences.emoji_level,
            "topicsToAvoid": preferences.topics_to_avoid,
            "phrasesToAvoid": preferences.phrases_to_avoid,
        }
        
        # Use new persona system
        return build_full_system_prompt(
            persona_name=preferences.selected_persona,
            user_name=user_name,
            user_gender=user_gender or "",
            preferences=prefs_dict,
            facts=facts_list,
            summary=summary_dict,
            custom_persona_name=preferences.custom_persona_name,
        )
    
    async def generate(
        self,
        messages: List[Dict],
        user_name: str,
        user_gender: Optional[str],
        preferences: UserPreferences,
        facts: List[Fact],
        summary: Optional[ThreadSummary] = None,
    ) -> str:
        """
        Generate complete (non-streaming) response from LLM.
        Returns the full response text at once.
        """
        system_prompt = self._build_system_prompt(user_name, user_gender, preferences, facts, summary)
        
        # Prepare messages for API
        api_messages = [{"role": "system", "content": system_prompt}]
        
        for msg in messages:
            role = "assistant" if msg.get("role") == "assistant" else "user"
            content = msg.get("content", "")
            
            # Handle images
            attachments = msg.get("attachments", [])
            if attachments:
                content_parts = []
                if content:
                    content_parts.append({"type": "text", "text": content})
                for att in attachments:
                    if att.get("kind") == "image" and att.get("downloadUrl"):
                        content_parts.append({
                            "type": "image_url",
                            "image_url": {"url": att["downloadUrl"]},
                        })
                api_messages.append({"role": role, "content": content_parts})
            else:
                api_messages.append({"role": role, "content": content})
        
        # Determine which model to use
        has_images = any(
            any(a.get("kind") == "image" for a in m.get("attachments", []))
            for m in messages
        )
        model = self.vision_model if has_images else self.model
        
        # Get complete response
        response = await self.client.chat.completions.create(
            model=model,
            messages=api_messages,
            temperature=0.9,
            max_tokens=1024,
        )
        
        return response.choices[0].message.content or ""
    
    async def generate_stream(
        self,
        messages: List[Dict],
        user_name: str,
        preferences: UserPreferences,
        facts: List[Fact],
        summary: Optional[ThreadSummary] = None,
    ) -> AsyncGenerator[str, None]:
        """
        Generate streaming response from LLM.
        
        Yields text chunks as they are generated.
        """
        system_prompt = self._build_system_prompt(user_name, preferences, facts, summary)
        
        # Prepare messages for API
        api_messages = [{"role": "system", "content": system_prompt}]
        
        for msg in messages:
            role = "assistant" if msg.get("role") == "assistant" else "user"
            content = msg.get("content", "")
            
            # Handle images
            attachments = msg.get("attachments", [])
            if attachments:
                content_parts = []
                if content:
                    content_parts.append({"type": "text", "text": content})
                for att in attachments:
                    if att.get("kind") == "image" and att.get("downloadUrl"):
                        content_parts.append({
                            "type": "image_url",
                            "image_url": {"url": att["downloadUrl"]},
                        })
                api_messages.append({"role": role, "content": content_parts})
            else:
                api_messages.append({"role": role, "content": content})
        
        # Determine which model to use
        has_images = any(
            any(a.get("kind") == "image" for a in m.get("attachments", []))
            for m in messages
        )
        model = self.vision_model if has_images else self.model
        
        # Stream response
        stream = await self.client.chat.completions.create(
            model=model,
            messages=api_messages,
            stream=True,
            temperature=0.9,
            max_tokens=1024,
        )
        
        async for chunk in stream:
            if chunk.choices and chunk.choices[0].delta.content:
                yield chunk.choices[0].delta.content
    
    async def extract_facts(
        self,
        messages: List[Dict],
        existing_facts: List[Fact],
    ) -> List[Dict]:
        """
        Extract new facts from conversation for memory curation.
        
        Returns list of fact dictionaries to create/update.
        """
        existing_facts_text = "\n".join([
            f"- {f.key}: {f.value}" for f in existing_facts
        ])
        
        messages_text = "\n".join([
            f"{m['role']}: {m['content']}" for m in messages
        ])
        
        prompt = f"""Analyze this conversation and extract important facts about the user that should be remembered long-term.

EXISTING FACTS (don't duplicate):
{existing_facts_text}

CONVERSATION:
{messages_text}

Extract new facts in the following categories:
- profile: Personal info (name, age, location, job, etc.)
- preference: Likes, dislikes, preferences
- project: Current projects, goals, activities
- emotional: Emotional states, concerns, needs
- constraint: Things to avoid, sensitivities

Return a JSON array of facts. Each fact should have:
- type: category from above
- key: short identifier
- value: the fact
- confidence: 0-1 how confident you are
- importance: 0-1 how important for future conversations

Only include genuinely new information. Return empty array if nothing new.
Return ONLY the JSON array, no other text."""

        response = await self.client.chat.completions.create(
            model=self.model,
            messages=[
                {"role": "system", "content": "You are a fact extraction assistant. You analyze conversations and extract important facts about the user."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
            max_tokens=1024,
        )
        
        try:
            content = response.choices[0].message.content.strip()
            # Handle potential markdown code blocks
            if content.startswith("```"):
                content = content.split("```")[1]
                if content.startswith("json"):
                    content = content[4:]
            facts = json.loads(content)
            return facts if isinstance(facts, list) else []
        except (json.JSONDecodeError, IndexError):
            return []


# Singleton instance
_llm_service: Optional[LLMService] = None


def get_llm_service() -> LLMService:
    """Get LLM service singleton."""
    global _llm_service
    if _llm_service is None:
        _llm_service = LLMService()
    return _llm_service
