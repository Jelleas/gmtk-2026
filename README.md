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
   - Each distraction:
     - Makes the clock tick faster (day passes quicker).
     - Increases your “risk” of being caught.

3. **Boss/Co‑worker Peeks**
   - At random intervals, a head pops up above the cubicle wall.
   - You have a short reaction window to:
     - Hide all distractions.
     - Switch back to “work” view on the monitor.
     - Stop phone/fidget spinner.

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
  - Working (default, slow time).
  - CRT Game.
  - Fidget Spinner.
  - Phone Under Desk.

- **Time Flow:**
  - Working: normal speed.
  - CRT Game: very fast.
  - Phone: fast.
  - Fidget Spinner: moderate.

You’re constantly swapping between these to make hours fly.

#### 3.2 Boss/Co‑worker Checks

- Heads randomly pop up above the cubicle wall:
  - Boss = more serious; getting caught hurts more.
  - Co‑worker = less serious; small penalty.

- Each peek:
  - Plays a short warning cue (sound or subtle screen flash).
  - After 1 second, they “look”:
    - If any distraction is active → caught.
    - If you’re working → okay.

Penalties (pick one simple rule for jam):

- Each caught:
  - Add extra real-time penalty or force a small extra task before you can resume distractions, and/or
  - Slow the clock for a few seconds (punishment phase).

---

### 4. Controls & Feedback

#### Controls

(Example keyboard layout):

- **Number keys to change activity:**
  - 1 – Work (turns monitor to boring work screen, hands on keyboard).
  - 2 – CRT Game.
  - 3 – Fidget Spinner.
  - 4 – Phone under desk.

- **Space / Right Mouse:**
  - “Panic” button – instantly switch back to Work (safe mode).

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
  - Clock that moves faster/slower based on current activity.
  - Activity switching (Work / CRT / Spinner / Phone).

**Day 2 – Peeks & Detection**
- Add boss/co‑worker heads that:
  - Randomly appear at the top.
  - Check your current activity after a short delay.
- Implement:
  - Strike system and simple game over.
  - Panic button to quickly go back to Work.

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