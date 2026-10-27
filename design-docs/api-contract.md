Status: draft for the build. Purpose: let the Flutter app (mock data first) and the AWS backend be built independently against the same JSON shapes. Swapping mocks for the real API should only mean changing the base URL.

1. Conventions
Base URL: https://{api-id}.execute-api.{region}.amazonaws.com/v1 (API Gateway + Lambda). CORS enabled for the CloudFront origin and localhost.
Format: JSON in and out, Content-Type: application/json. Field names are camelCase.
Auth: none. A single hard-coded demo user (demo). Do not build sign-up or login.
IDs: opaque strings with a readable prefix (rec_, ver_, sess_, evt_).
Timestamps: ISO 8601 UTC, e.g. 2026-10-23T18:30:00Z.
Voice is text-first. Every voice feature is “transcribe, then call the same text endpoint”. Nothing else in the API changes when voice is added.
Errors: always this shape, with an HTTP status that matches:
json
{ "error": { "code": "session_finished", "message": "This cooking session is already finished." } }
Status	Code	When
400	bad_request	Missing or invalid field
404	not_found	Unknown recipe, session, or event
409	session_finished	Writing to a finished session
422	unparseable	Model output could not be turned into structured data
502	model_error	Upstream model call failed
504	model_timeout	Upstream model call too slow

The client shows a short retry message for 422, 502 and 504, and keeps the text input available as a fallback.

2. Data model
Recipe
json
{
  "id": "rec_lasagne",
  "title": "Lasagne",
  "ingredients": [
    { "name": "fresh basil", "quantity": "1 handful", "unit": null }
  ],
  "steps": [
    { "index": 3, "text": "Stir in the basil, then simmer for 10 minutes, stirring now and then.", "timerSeconds": 600 }
  ],
  "versionCount": 3,
  "avgRating": 4.0,
  "lastCookedAt": "2026-10-23T18:30:00Z",
  "latestSwap": "dried basil for fresh basil"
}
steps[].index is zero-based. The UI shows index + 1 of steps.length.
timerSeconds is null when the step has no timing. It is extracted when the recipe is parsed.
versionCount, avgRating, lastCookedAt and latestSwap are derived by the backend and are what the Recipes list screen renders. latestSwap is null for an original-only recipe.
Version

Version 1 is the original recipe (no substitutions). Every finished cooking session creates the next version.

json
{
  "id": "ver_lasagne_3",
  "recipeId": "rec_lasagne",
  "number": 3,
  "createdAt": "2026-10-23T18:30:00Z",
  "rating": 4,
  "note": "Fine, slightly less fresh. Use a bit more next time.",
  "substitutions": [
    { "original": "fresh basil", "replacement": "dried basil", "quantity": "1 tsp", "stepIndex": 3 }
  ]
}
Cooking session and events
json
{
  "id": "sess_01",
  "recipeId": "rec_lasagne",
  "status": "active",
  "currentStep": 3,
  "startedAt": "2026-10-23T18:05:00Z",
  "events": []
}

An event is one thing the cook said during the session:

json
{
  "id": "evt_01",
  "type": "substitution",
  "status": "pending",
  "stepIndex": 3,
  "rawText": "I’m using dried basil instead of the fresh",
  "parsed": { "original": "fresh basil", "replacement": "dried basil", "quantity": "1 tsp" },
  "readBack": "Noted: dried basil instead of fresh basil, about 1 tsp. Right?"
}
type: substitution, quantity_change, timing_change, note, or unclear.
status: pending (waiting for the cook to confirm), confirmed, undone.
Only confirmed events are copied into the version when the session finishes.
parsed is null for note and unclear. For substitution, quantity may be null, and readBack then asks a short follow-up (“How much dried basil?”).
3. Endpoints
Recipes
Method	Path	Purpose	Screen
GET	/recipes	List all recipes	Recipes
GET	/recipes/{id}	One recipe	Recipe detail
GET	/recipes/{id}/versions	Versions, newest first	Recipe detail
POST	/recipes/parse	Turn pasted text into a draft recipe (not saved)	Add recipe
POST	/recipes	Save a reviewed draft	Add recipe

GET /recipes → 200

json
{ "recipes": [ /* Recipe, without full steps if you want a lighter payload */ ] }

POST /recipes/parse

json
{ "rawText": "Lasagne. 500g mince, 1 onion, fresh basil... Step 1: ..." }

Response 200: { "draft": { "title": "...", "ingredients": [...], "steps": [...] } }. The draft has the same shape as a Recipe without id or the derived fields. The client shows it for a quick review and edit.

POST /recipes with { "draft": { ... } } → 201 with the saved Recipe.

Cooking sessions
Method	Path	Purpose
POST	/recipes/{id}/sessions	Start cooking
PATCH	/sessions/{id}	Move to another step
POST	/sessions/{id}/events	Send something the cook said
POST	/sessions/{id}/events/{eventId}/confirm	Cook confirms the read-back
POST	/sessions/{id}/events/{eventId}/undo	Cook undoes an event
POST	/sessions/{id}/finish	Rate and save as a new version

POST /recipes/{id}/sessions (empty body) → 201: { "session": { ... }, "recipe": { ... } }.

PATCH /sessions/{id} with { "currentStep": 4 } → 200 with the session. Used by Next step and Back.

POST /sessions/{id}/events

json
{ "text": "I’m using dried basil instead of the fresh" }

Response 201: { "event": { ... } } with status: "pending" and a readBack line. The backend uses session.currentStep as stepIndex. This is one extraction call (structured JSON out), not an agent loop, so it stays fast.

If the text is not understood: type: "unclear", status: "pending", parsed: null, readBack: "Sorry, I didn’t catch that. Say it again or type it.". The client shows the message and no Yes button.

Fix is not its own endpoint. The client calls undo and then sends the corrected text as a new event.

POST …/confirm and POST …/undo (empty body) → 200 with the updated event.

POST /sessions/{id}/finish

json
{ "rating": 4, "note": "Fine, slightly less fresh. Use a bit more next time." }

Response 201: { "version": { ... }, "recipe": { ... } }. rating is an integer 1–5. note is optional. Finishing with no confirmed events is allowed and creates a version with an empty substitutions list.

Ask

POST /ask (stateless; the client sends the last few turns as context)

json
{
  "question": "I want to make lasagne but I don’t have fresh basil. Have I used dried before, or maybe fresh coriander, and did it work?",
  "history": [ { "role": "user", "text": "..." }, { "role": "assistant", "text": "..." } ]
}

Response 200:

json
{
  "answer": "Yes, both. Dried basil worked well last time (4/5). Fresh coriander got 2/5, and you noted it tasted soapy. I would go with dried basil, about 1 tsp.",
  "basedOn": "history",
  "sources": [
    { "versionId": "ver_lasagne_3", "recipeId": "rec_lasagne", "recipeTitle": "Lasagne", "versionNumber": 3, "date": "2026-10-23", "rating": 4, "summary": "dried basil for fresh basil" },
    { "versionId": "ver_lasagne_2", "recipeId": "rec_lasagne", "recipeTitle": "Lasagne", "versionNumber": 2, "date": "2026-09-12", "rating": 2, "summary": "fresh coriander for fresh basil" }
  ]
}
basedOn: history (answer comes from the user’s own versions), general (no history, general cooking knowledge), or mixed. The UI shows the “From your history” cards only when sources is not empty.
With no history the answer must say so plainly (“You haven’t cooked this before…”) and return sources: [].
Every claim about the user’s past cooking must be backed by an entry in sources.
Voice (added last)

POST /transcribe with { "audioBase64": "...", "mimeType": "audio/mp4" } → 200: { "text": "..." }. Keep clips short (API Gateway’s payload limit is about 10 MB). The client then sends the text to /sessions/{id}/events or /ask. The browser records audio/webm on most platforms and audio/mp4 on iOS Safari, so the backend must accept both.

Dev only

POST /dev/reset reloads the seed data. Remove it or protect it before sharing the live link publicly.

4. Screens to endpoints
Screen	Calls
Recipes	GET /recipes
Recipe detail	GET /recipes/{id}, GET /recipes/{id}/versions
Add recipe	POST /recipes/parse, then POST /recipes
Cooking	POST /recipes/{id}/sessions, PATCH /sessions/{id}, POST …/events, …/confirm, …/undo
Finish and rate	POST /sessions/{id}/finish
Ask	POST /ask
Any mic button	POST /transcribe, then the text endpoint above
5. Backend notes

Extraction call (events). One model call with a JSON schema: type, original, replacement, quantity, readBack. Temperature low. Validate the output; on failure return 422 unparseable.

Ask agent tools. Keep the tool list small:

search_substitutions(original, replacement?) returns past versions where that swap was made, with rating and note.
get_recipe(recipeId) returns the recipe.
list_versions(recipeId) returns the versions with notes.

Order of reasoning: check the user’s own history first, then fall back to general cooking knowledge, and report which one was used via basedOn.

Matching swaps. Store normalised names (originalNorm, replacementNorm: lowercase, singular, no quantities) next to the display names. Lookups use the normalised fields, not embeddings alone.

DynamoDB single table (suggestion).

Item	PK	SK
Recipe	USER#demo	REC#{id}
Version	REC#{id}	VER#{number}
Session	SESS#{id}	META
Event	SESS#{id}	EVT#{timestamp}
Substitution lookup (GSI1)	USER#demo#SUB#{originalNorm}	{replacementNorm}#{date}

Write one GSI1 item per substitution when a session finishes, so “what happened when I replaced fresh basil?” is a single query.

6. Seed data

The Flutter mocks and the seed script should use the same file. Minimum set:

Lasagne: v1 original; v2 (2026-09-12) fresh coriander for fresh basil, rating 2, note “tasted soapy”; v3 (2026-10-23) dried basil for fresh basil, rating 4.
Chicken tagine: v2 ras el hanout for cumin, rating 4 to 5.
Shakshuka: one swap, tinned for fresh tomatoes.
Dal tadka: original only.

Test Ask once on a recipe with no history, and once on a freshly added recipe.

7. Open decisions
Whether GET /recipes returns full steps or a light summary (start with full; it is a small dataset).
Whether the Ask history array should be capped (suggest the last 6 turns).
Exact model and tool-calling behaviour: to be confirmed in the first hour of testing with the Meta Model API.
Whether the official rules restrict where or how the project may be built (published Oct 26): confirm before writing real code.