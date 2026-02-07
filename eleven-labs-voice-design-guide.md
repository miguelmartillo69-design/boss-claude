# ElevenLabs Voice Design — Prompting Guide

Reference guide for crafting voice prompts in ElevenLabs Voice Design. Use this when helping create custom voices.

---

## How It Works

- Go to **Voices > My Voices > Add a new voice > Voice Design** (or use the API)
- Write a text prompt describing the voice + preview text for it to speak
- ElevenLabs generates **3 voice options** per request
- You only pay credits once (for the preview text character count), not 3x
- Saving a voice consumes one voice slot

---

## Prompt Construction Framework

Build prompts by layering these attributes in order of importance. Not all are required — use what matters for the target voice.

### 1. Gender + Age (Foundation)

Start here. These set the baseline vocal identity.

| Descriptor | Effect |
|---|---|
| `adolescent male/female` | Youthful, lighter vocal weight |
| `young adult` / `in their 20s` / `early 30s` | Energetic, clear |
| `middle-aged man/woman` / `in his/her 40s` | Mature, fuller |
| `elderly man/woman` / `in his 80s` | Weathered, slower, textured |
| `gender-neutral` / `ambiguous gender` | Soft, mid-pitched, androgynous |

### 2. Tone / Timbre / Pitch (Physical Voice Quality)

This is the *sound* of the voice — distinct from emotion or delivery style.

| Category | Descriptors |
|---|---|
| **Pitch** | `deep`, `low-pitched`, `high-pitched`, `mid-pitched`, `normal pitch` |
| **Texture** | `smooth`, `gravelly`, `raspy`, `breathy`, `airy`, `nasally`, `throaty` |
| **Warmth** | `warm`, `mellow`, `rich`, `buttery` |
| **Edge** | `harsh`, `shrill`, `tinny`, `metallic` |
| **Power** | `booming`, `resonant`, `light`, `thin` |
| **Special** | `robotic`, `ethereal`, `husky` |

Combine freely: "A deep, gravelly, warm voice" or "Light and breathy with a slight rasp."

### 3. Accent (Regional/Cultural Identity)

Critical for character voices. Be specific, not vague.

**Key tip**: Use "thick" instead of "strong" for accent prominence — it produces more consistent results.

| Accent Intensity | Phrasing |
|---|---|
| Heavy | `thick [X] accent` |
| Moderate | `noticeable [X] accent` |
| Light | `slight [X] accent`, `soft [X] lilt` |
| Neutral | `neutral American accent`, `standard British accent` |

**Good examples:**
- `thick French accent`
- `slight Southern drawl`
- `heavy Eastern European accent`
- `crisp British accent`
- `soft Irish lilt`
- `regional Australian accent, laid-back and nasal`

**For fantasy/fictional characters**, reference real accents as inspiration:
- `An elf with a proper thick British accent. He is regal and lyrical.`
- `A goblin with a raspy Eastern European accent.`

**Avoid**: "foreign", "exotic", or other vague terms.

### 4. Pacing (Speed + Rhythm)

| Speed | Descriptors |
|---|---|
| Fast | `speaking quickly`, `at a fast pace`, `hurried cadence`, `rapid` |
| Normal | `at a normal pace`, `natural/conversational pace`, `normal cadence` |
| Slow | `speaking slowly`, `slow rhythm`, `deliberate and measured`, `drawn out, savoring each word` |
| Varied | `erratic pacing with abrupt pauses and bursts`, `staccato delivery` |
| Stylistic | `relaxed and conversational`, `rhythmic and musical`, `even pacing with consistent timing` |

### 5. Emotion / Personality (Delivery Style)

| Type | Descriptors |
|---|---|
| Energy | `energetic`, `excited`, `lively`, `enthusiastic`, `high-energy` |
| Calm | `calm`, `reflective`, `relaxed`, `soothing` |
| Negative | `sad`, `emotional`, `angry`, `cynical`, `world-weary` |
| Attitude | `sarcastic`, `dry`, `sweet`, `tough`, `authoritative` |
| Character | `eccentric`, `silly`, `dramatic`, `passionate` |

### 6. Character / Profession (Optional Shorthand)

Using a character archetype can communicate a lot in few words:

`pirate`, `businessman`, `farmer`, `politician`, `therapist`, `ogre`, `godlike being`, `TV announcer`, `drill sergeant`, `mad scientist`, `sports commentator`

### 7. Audio Quality (Production Context)

| Goal | Phrase to Include |
|---|---|
| Clean/polished | `perfect audio quality`, `studio-quality recording` |
| Intentionally rough | `low-fidelity audio`, `poor audio quality` |
| Specific effect | `sounds like a voicemail`, `muffled and distant, like on an old tape recorder` |
| Default (no preference) | Omit quality descriptors entirely |

**Warning**: Adding "perfect audio quality" can sometimes reduce prompt accuracy for very specific/niche voices. Use it when clarity matters more than specificity.

**Tip**: Phrasing variations can produce different results. Try both `Perfect audio quality` and `The audio quality is perfect`.

---

## Prompt Template

Use this as a starting skeleton. Drop any line that doesn't apply.

```
[Audio quality statement]. A [age descriptor] [gender] with a [accent intensity] [accent type] accent.
[His/Her/Their] voice is [tone/timbre descriptors]. [He/She/They] speak[s] [pacing descriptor],
with a [emotion/personality] delivery. [Optional character/profession context].
```

**Example built from template:**
```
Excellent audio quality. A man in his 30s to early 40s with a thick British accent
speaking at a natural pace like he's talking to a friend.
```

---

## Preview Text Best Practices

The preview text is the script the voice will speak during generation. It matters a lot.

### Rules

1. **Match the voice's personality** — Don't give a calm, reflective voice an angry shouting script
2. **Use longer text** — Full sentences or short paragraphs produce more stable, expressive results. Short phrases sound abrupt
3. **Include performance cues** — Use `[laughs]`, `[sighs]`, `[exhales]`, `[lip smacks]`, `[light chuckle]`, `(maniacal laughter)` for natural texture
4. **Use caps for emphasis** — `WHAT A GOAL!`, `NO CHANCE!`, `FASCINATING` to guide intensity
5. **Use punctuation for pacing** — Ellipses for pauses (`I see... a promise`), em dashes for interruptions (`chaos—one hero`), commas for breath
6. **Write in-character** — If the voice is a pirate, write pirate dialogue. If Southern, use colloquialisms

### Bad Match (don't do this)
- **Prompt**: "calm, reflective younger female voice with a slight Japanese accent"
- **Preview**: "Hey! I can't stand what you've done with the darn place!!!"

### Good Match
- **Prompt**: "calm, reflective younger female voice with a slight Japanese accent"
- **Preview**: "It's been quiet lately... I've had time to think, and maybe that's what I needed most."

---

## Guidance Scale

Controls how strictly the model follows your prompt vs. how much creative freedom it takes.

| Value | When to Use |
|---|---|
| **Low (20-25%)** | Performance/audio quality matters more than nailing every prompt detail. Good for dramatic, emotional, or broadly-typed voices (movie trailers, fantasy creatures) |
| **Medium (30-35%)** | Balanced. Good default for character voices where you want accuracy but natural delivery |
| **High (38-50%)** | Accent or tone accuracy is paramount. Use for specific regional accents, precise character types, or when the voice must match the prompt exactly |

**Tradeoff**: Higher values = more prompt-accurate but potentially lower audio quality for niche prompts. Lower values = better audio quality but less precise adherence.

---

## Reference Examples

### Quick-and-Dirty Voices (Short Prompts)

These work when you want something broadly usable:
- `A calm male narrator`
- `A cute little squeaky mouse`
- `An angry old pirate, loud and boisterous`
- `Dramatic voice for movie trailers`

### Detailed Character Voices (Long Prompts)

For specific characters, layer the attributes:

**Relatable Entrepreneur:**
`Excellent audio quality. A man in his 30s to early 40s with a thick British accent speaking at a natural pace like he's talking to a friend.`
→ Guidance: 40%

**Southern Woman:**
`An older woman with a thick Southern accent. She is sweet and sarcastic.`
→ Guidance: 35%

**New Yorker:**
`Deep, gravelly thick New York accent, tough and world-weary, often cynical.`
→ Guidance: 40%

**Mad Scientist:**
`A voice of an eccentric scientific genius with rapid, erratic speech patterns that accelerate with excitement. His German-tinged accent becomes more pronounced when agitated. The pitch varies widely from contemplative murmurs to manic exclamations, with frequent eruptions of maniacal laughter.`
→ Guidance: 38%

**Sports Commentator:**
`A high-energy female sports commentator with a thick British accent, passionately delivering play-by-play coverage of a football match in a very quick pace. Her voice is lively, enthusiastic, and fully immersed in the action.`
→ Guidance: 25%

---

## Workflow for Creating a Voice

1. **Define the purpose** — What will this voice be used for? (narration, character, assistant, ad, etc.)
2. **List key attributes** — Pick 3-5 from: gender, age, accent, tone, pacing, emotion, character type
3. **Draft the prompt** — Layer attributes using the template above
4. **Write matching preview text** — In-character, longer is better, include performance cues
5. **Set guidance scale** — Start at 30% as baseline, adjust up for accent precision or down for quality
6. **Generate and compare** — Review all 3 options, iterate on prompt if none fit
7. **Experiment with phrasing** — Rearrange descriptors, try synonyms, adjust emphasis

---

## Prompting Tips Summary

- More descriptive = more accurate (for specific voices)
- Simple prompts work for neutral/general voices
- "Thick" > "strong" for accent intensity
- Combine accent with age, tone, and pacing for better control
- Preview text should complement, not contradict, the prompt
- Longer preview text = more stable output
- Try phrasing variations (`Perfect audio quality` vs `The audio quality is perfect`)
- Quality descriptors can trade off against prompt specificity
- Place quality phrases at beginning or end of prompt
