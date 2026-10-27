Simmer – design handoff for the Flutter web app

Use this together with al-gusto-api-contract.md. It describes the four designed screens in plain text, plus guidance for the two screens that are not designed yet. Mobile first: design for a 390 × 844 frame; on wider screens, centre a column of max width 430 px.

Design tokens

Colours

Token	Hex	Use
ink	
#1B2420	Main text on light, text on accent buttons
muted	
#55605A	Secondary text on light
bg	
#F4F6F3	Light screen background (sage tint)
card	
#FFFFFF	Cards, inputs, bars
line	
#D9DFD9	1 px borders on light
green	
#2F5D46	Ratings, active tab, user chat bubble, outline buttons
accent	
#C5DC5A	Primary buttons, mic, highlights (fresh herb)
accent edge	
#8DA52E	1 px inset outline on accent buttons on light screens
dark bg	
#16201B	Cooking mode background
dark surface	
#22302A	Cards and chips on dark
dark line	
#3A4A41	Borders on dark
dark muted	
#A9B5AE	Secondary text on dark
dark text	
#F4F6F3	Main text on dark
progress track	
#2A3A32	Progress bar track on dark

Type

Headings, recipe titles, big numbers: Bricolage Grotesque (600 or 700).
Everything else: DM Sans (400, 500, 700).
Small caps labels: 13 px, uppercase, letter-spacing 0.06em, muted colour.
Body 16 px, secondary 14–15 px. Minimum tap target 44 px high.

Shape: cards radius 16, inputs radius 12, pill buttons fully rounded. Page side padding 20. Card gap 12.

Bottom tab bar (Recipes and Ask screens only): 76 px high, white, 1 px top border. Two equal tabs, “Recipes” and “Ask”, 15 px. Active tab is green, bold, with a 3 px green line along the top edge. Inactive is muted, weight 500.

Screen 1: Recipes (home)
Top padding 56. Title “Simmer” (Bricolage 700, 30). Under it “Recipes, to taste.” (15, muted).
Search field below: 48 px high, white, border line, radius 12, placeholder “Search your recipes”.
List of recipe cards (white, border line, radius 16, padding 16, 6 px between lines):
Row 1: recipe title (Bricolage 600, 20) on the left, rating on the right (“★ 4.0”, green, bold).
Row 2: “3 versions · last cooked Oct 23” (14, muted).
Row 3: “Latest swap: dried basil for fresh basil” (14), or “Original recipe” if there are no swaps.
Floating button “+ Add recipe”: bottom right, 20 px from the right, 92 px from the bottom (above the tab bar). 52 high, accent background with ink text, 16 bold, radius 26.
Data: GET /recipes. Tap a card to open Recipe detail.
Screen 2: Cooking mode (dark, full screen, no tab bar)

Top to bottom, side padding 20, top padding 56:

Header row: “Close” (muted, 16, 44 px tap target) on the left; “Lasagne · Step 4 of 9” (15, dark muted) on the right.
Progress bar: 6 px high, radius 3, track colour, accent fill. Fill width is step number divided by total steps.
Current step text: Bricolage 600, 30, line height 1.2, margin 20 above and 16 below.
Timer card (only when the step has timerSeconds): dark surface, radius 16, padding 12 × 16. Left: small caps label (e.g. “SIMMER”) and the time “10:00” in Bricolage 700, 44. Right: “Start timer” pill (52 high, accent, ink text, 17 bold). Once running, the time counts down and the button becomes “Pause”. At zero, vibrate or play a sound, and show “Time’s up”.
“Ingredients (12)” button: full width, 48 high, border dark line, radius 12, left-aligned text. Expands to show the ingredient list.
Small caps label “LOGGED SO FAR”, then one chip per confirmed event: dark surface, radius 12, text like “fresh basil → dried basil · 1 tsp” (16) and an “Undo” text button on the right (accent colour, 15 bold, 44 high).
Confirm card (shown when an event is pending): 2 px accent border, radius 14, padding 12 × 14. The readBack text (16), then two buttons side by side, 44 high, radius 10: “Yes” (accent fill, ink text) and “Fix” (1 px outline in dark text colour). “Yes” calls confirm. “Fix” calls undo and focuses the text input. For an unclear event, show the message without a Yes button.
Bottom area:
Row 104 px from the bottom: “Type instead” pill (44 high, dark line border) on the left; round mic button, 72 px, accent fill, ink microphone icon, on the right. Mic is tap to talk. Until voice is built, the mic opens the same text input.
Navigation row 28 px from the bottom: “Back” (104 wide, 60 high, outlined pill) and “Next step” (fills the rest, 60 high, pill with light fill 
#F4F6F3 and dark text 
#16201B, 18 bold). On the last step, “Next step” reads “Finish cooking” and opens the Finish screen.
Keep the screen awake while this screen is open.
Calls: start with POST /recipes/{id}/sessions; Next/Back with PATCH /sessions/{id}; spoken or typed text with POST /sessions/{id}/events.
Screen 3: Finish and rate (light, no tab bar)
Small line “Lasagne · version 3” (15, muted). Title “How did it turn out?” (Bricolage 700, 30).
“What you changed” card: white, border, radius 16, padding 16. Small caps label, then each confirmed swap on its own line (17), e.g. “fresh basil → dried basil · 1 tsp”. If there are none, show “No changes. Cooked as written.”
Star rating: five 40 px stars, 6 px apart. Filled stars are green; empty stars are green outlines. Tappable.
“Notes” label (15, bold) and a multiline field (120 high, radius 12, white, border). Below it an outlined pill “Add note by voice” (48 high, green border and text).
“Save as version N” button pinned 32 px from the bottom: full width, 56 high, accent fill with edge outline, ink text, 17 bold, radius 28. Calls POST /sessions/{id}/finish, then goes back to the recipe.
Screen 4: Ask (light, tab bar)
Title “Ask” (Bricolage 700, 30).
Chat area. User bubble: right aligned, max width 300, green fill, white text, radius 16 with a 4 px bottom-right corner. Assistant bubble: left aligned, max width 320, white, border line, radius 16 with a 4 px bottom-left corner. Text 16, line height about 1.45.
Under an assistant answer that has sources, show the small caps label “FROM YOUR HISTORY” and one card per source (white, border, radius 14, padding 12 × 14): bold line “Lasagne v3 · Oct 23 · ★ 4”, then a 14 px muted line with the summary. Tapping a card opens that recipe version. Show no sources section when sources is empty.
Input bar pinned above the tab bar: text field (52 high, radius 26, white, border, placeholder “Ask about your cooking”) and a round 52 px accent mic button. Calls POST /ask.
Not designed yet (build in the same style)
Recipe detail: recipe title, ingredients, steps, a large primary “Start cooking” button (accent), and a “Versions” list below. Each version row shows “v3 · Oct 23 · ★ 4” and the swap summary, like the source cards on Ask. Data: GET /recipes/{id} and /versions.
Add recipe: one big multiline field for pasting a recipe, a “Parse” button, then an editable review of the title, ingredients and steps, and “Save”. Data: POST /recipes/parse, then POST /recipes.
Timer running state: described in the cooking mode section above.
Build notes
Build against the mock data first, in exactly the JSON shapes of the API contract, so switching to the real API is only a base URL change.
Check which Flutter packages work on web and iOS Safari for microphone recording and for keeping the screen awake before choosing them. Microphone access needs HTTPS.
Load the two fonts through a Flutter font package or bundle them as assets.
No login, no onboarding. The app opens with seeded recipes.