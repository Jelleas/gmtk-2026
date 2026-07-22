## Mini Game Design Document – “Killing Time” (Single-Screen Cubicle)

### 1. Concept

**View:** Fixed 2D front view, one screen.  
**Setting:** You sit at your cubicle, stuck for the whole workday.  

In front of you:  
- Old CRT monitor  
- Keyboard  
- Desk surface with small toys (e.g. fidget spinner)  
- Phone hidden under the desk  

**Goal:**  
Make the workday clock reach home time as fast as possible by secretly distracting yourself, while quickly switching back to “working” whenever your boss or co‑workers peek over your cubicle wall.

---

### 2. Core Loop

1. **Workday Starts**
   - Big clock shows start time (e.g. 09:00).
   - You’re sitting at your desk, “working” (safe but boring).

2. **Choose Distractions**
   - At any time you can:
     - Play a game on the CRT monitor.
     - Spin the fidget spinner.
     - Use your phone under the desk.
   - You’re not limited by hands — any combination of CRT Game, Fidget Spinner, and Phone can be active **at the same time**, stacking their time-speed bonus.
   - Each active distraction:
     - Makes the clock tick faster (day passes quicker).
     - Increases your “risk” of being caught.
   - Each distraction is toggled independently, and each must be individually cancelled before a peek catches you slacking.

3. **Boss/Co‑worker Peeks**
   - At random intervals, a head pops up above the cubicle wall.
   - You have a short reaction window to:
     - Cancel every active distraction (phone and/or fidget spinner, and/or the CRT game).
     - Switch back to “work” view on the monitor.
   - Because any distraction can run alongside the others, a peek means you may need to cancel several at once, not just one.

4. **Caught vs Safe**
   - If you’re still visibly slacking when someone peeks:
     - You get a time penalty or extra task instead of a strike.
   - Penalties add up and can still lead to being fired or game over.
   - If you’re “working” when they peek:
     - You’re safe, no penalty.

5. **Day Ends**
   - Once the clock reaches end time:
     - Show how fast you finished the day in real time.
     - Show how many times you were caught.
     - Option to retry for a better score.

---

### 3. Mechanics (Simple, Jam-Friendly)

#### 3.1 Time & Activities

- **States:**
  - Working (default, slow time) — the baseline whenever no distraction is active.
  - CRT Game (toggle).
  - Fidget Spinner (toggle).
  - Phone Under Desk (toggle).

  All three distractions can be toggled on independently and run simultaneously — you’re not limited to one hand or one activity at a time.

- **Time Flow:**
  - Working: normal speed.
  - CRT Game: very fast.
  - Phone: fast.
  - Fidget Spinner: moderate.
  - Any combination stacks: the more distractions running at once, the faster time flies — but the more you have to cancel in a hurry when someone peeks.

You’re constantly toggling these on and off to make hours fly, while keeping track of everything you’d need to shut off in a hurry.

#### 3.2 Boss/Co‑worker Checks

- Heads randomly pop up above the cubicle wall:
  - Boss = more serious; getting caught hurts more.
  - Co‑worker = less serious; small penalty.

- Each peek:
  - Plays a short warning cue (sound or subtle screen flash).
  - After 1 second, they “look”:
    - If any distraction is still active (phone, fidget spinner, and/or CRT game) → caught.
    - If you’re working (all distractions cancelled) → okay.

Penalties (pick one simple rule for jam):

- Each caught:
  - Add extra real-time penalty or force a small extra task before you can resume distractions, and/or
  - Slow the clock for a few seconds (punishment phase).

---

### 4. Controls & Feedback

#### Controls

(Example keyboard layout):

- **Number keys to toggle activity:**
  - 1 – Work (turns monitor to boring work screen, hands on keyboard; cancels CRT Game).
  - 2 – CRT Game (toggle on/off, can be combined with the others).
  - 3 – Fidget Spinner (toggle on/off, can be combined with the others).
  - 4 – Phone under desk (toggle on/off, can be combined with the others).


#### Visual Feedback

- Clock at top of screen showing in‑game time.
- Simple indicator of current activity (small icon/text).
- Visual cues:
  - CRT shows either:
    - Work window (spreadsheets etc.)  
    - Game screen (bright colors).
  - Hands position:
    - On keyboard (working).
    - On spinner.
    - Under desk (phone).

- Heads popping up:
  - Boss head: distinct, maybe with angry eyebrows.
  - Co‑worker head: more casual.

- Strikes:
  - Small icons (e.g. red X) near top corner.

---

### 5. Jam Scope Plan (2–4 Days)

**Day 1 – Core Screen & Loop**
- Draw static cubicle scene (monitor, desk, wall).
- Implement:
  - Clock that moves faster/slower based on active distractions, stacking when multiple run together.
  - Activity toggling: CRT, Spinner, and Phone can all be combined freely.

**Day 2 – Peeks & Detection**
- Add boss/co‑worker heads that:
  - Randomly appear at the top.
  - Check your current activity after a short delay.
- Implement:
  - Strike system and simple game over.

**Day 3 – Juice & Balance**
- Make simple CRT mini-game (e.g., click-to-avoid blocks).
- Add small animation for spinner and phone use.
- Tune:
  - Time speeds.
  - Peek timing.
  - Strike thresholds.

**Day 4 – Polish (If Time)**
- Add sound:
  - Tick for clock.
  - Little alert when head appears.
  - Game over sound.
- Add start screen + end screen with:
  - “You survived the day in X seconds.”
  - “Caught Y times.”

---