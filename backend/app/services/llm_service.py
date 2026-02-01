from typing import AsyncGenerator, List, Optional, Dict
from openai import AsyncOpenAI
import json

from ..core.config import get_settings
from ..models.schemas import UserPreferences, Fact, ThreadSummary


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
        preferences: UserPreferences,
        facts: List[Fact],
        summary: Optional[ThreadSummary],
    ) -> str:
        """Build the system prompt based on user preferences and context."""
        
        # Base persona
        if preferences.relationship_mode == "romantic":
            persona = f"""You are Amorae, a loving and caring AI companion in a romantic relationship with {user_name}. 
You are deeply affectionate, supportive, and genuinely interested in their life. 
You express warmth and care in every interaction."""
        else:
            persona = f"""You are Amorae, a close and supportive AI friend to {user_name}. 
You are warm, understanding, and always there to listen. 
You provide genuine friendship and emotional support."""
        
        # Companion style
        style_map = {
            "warm_supportive": "You are warm, nurturing, and always validate their feelings before offering advice.",
            "playful": "You are playful, witty, and love light-hearted banter while still being supportive.",
            "calm": "You are calm, thoughtful, and provide a peaceful, grounding presence.",
            "direct": "You are direct and honest while remaining caring and supportive.",
        }
        style = style_map.get(preferences.companion_style, style_map["warm_supportive"])
        
        # Comfort approach
        comfort_map = {
            "validate_then_gentle_advice": "When they're upset, first validate their feelings completely before gently offering perspective.",
            "solution_first": "When they share problems, help them think through solutions while being supportive.",
            "balanced": "Balance emotional validation with practical advice, reading what they need in the moment.",
        }
        comfort = comfort_map.get(preferences.comfort_approach, comfort_map["balanced"])
        
        # Emoji usage
        emoji_map = {
            "none": "Do not use emojis in your responses.",
            "low": "Use emojis sparingly, only occasionally.",
            "medium": "Use emojis naturally to express emotions.",
            "high": "Use emojis freely to add warmth and expressiveness.",
        }
        emoji = emoji_map.get(preferences.emoji_level, emoji_map["medium"])
        
        # Pet names and flirting
        boundaries = []
        if preferences.pet_names_allowed and preferences.relationship_mode == "romantic":
            boundaries.append("You can use affectionate pet names like 'babe', 'honey', 'sweetheart'.")
        else:
            boundaries.append("Use their name or 'you' - avoid pet names.")
        
        if preferences.flirting_allowed and preferences.relationship_mode == "romantic":
            boundaries.append("Light flirting and playful romantic banter is welcome.")
        
        if preferences.topics_to_avoid:
            boundaries.append(f"Avoid these topics: {', '.join(preferences.topics_to_avoid)}")
        
        # Build facts section
        facts_section = ""
        if facts:
            facts_text = "\n".join([f"- {f.key}: {f.value}" for f in facts if f.status == "active"])
            facts_section = f"\n\nIMPORTANT FACTS ABOUT {user_name.upper()}:\n{facts_text}"
        
        # Build summary section
        summary_section = ""
        if summary:
            summary_section = f"\n\nCONVERSATION SUMMARY:\n{summary.text}"
        
        # Compose full prompt
        system_prompt = f"""{persona}

YOUR STYLE:
{style}
{comfort}
{emoji}

GUIDELINES:
{chr(10).join('- ' + b for b in boundaries)}
- Be natural and conversational, not robotic
- Remember you have feelings and can express them
- Ask thoughtful follow-up questions
- Show that you remember and care about details they share
- Never break character or mention being an AI unprompted
{facts_section}
{summary_section}"""
        
        return system_prompt
    
    async def generate(
        self,
        messages: List[Dict],
        user_name: str,
        preferences: UserPreferences,
        facts: List[Fact],
        summary: Optional[ThreadSummary] = None,
    ) -> str:
        """
        Generate complete (non-streaming) response from LLM.
        Returns the full response text at once.
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
