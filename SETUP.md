# The Work — setup guide

A two-sided golf practice app built around **one shared sheet**. A coach builds
the drill library and can seed a player's day; the player logs the actual work,
ticks each drill done, and adds notes. Both look at the identical day grid —
pick a drill and the club, category, distance, defaults and goal fill in
automatically (the VLOOKUP), with live totals at the bottom.

You'll wire up three free services:

- **GitHub** — stores the code
- **Netlify** — publishes it as a live URL (the link your coach opens)
- **Supabase** — handles logins and saves all the data

Cost: **£0**. Time: about **30–40 minutes** the first time. No coding needed —
it's copy, paste, click.

---

## Part 1 — Supabase (database + logins)

1. Go to **supabase.com** → **Start your project** → sign in.
2. **New project**. Name it (e.g. `the-work`), set a database password (save it),
   pick the nearest region, **Create**. Wait ~2 minutes.
3. Left sidebar → **SQL Editor** → **New query**.
4. Open **`schema.sql`** from this folder, copy everything, paste, click **Run**.
   You should see "Success." This builds every table, the lookup fields, and the
   security rules.
5. Left sidebar → **Project Settings** (gear) → **API**. Copy two values:
   - **Project URL** (e.g. `https://abcd1234.supabase.co`)
   - **anon public** key (long string under "Project API keys")

---

## Part 2 — Put your keys in the app

1. Open **`index.html`** in any text editor.
2. Near the top of the `<script>` block, replace the two placeholders:

   ```js
   const SUPABASE_URL = "PASTE_YOUR_PROJECT_URL_HERE";
   const SUPABASE_ANON_KEY = "PASTE_YOUR_ANON_PUBLIC_KEY_HERE";
   ```

   with your Project URL and anon public key. Keep the quote marks. Save.

> The anon key is meant to be public — your data is protected by the security
> rules from `schema.sql`, not by hiding the key.

---

## Part 3 — Code onto GitHub

1. **github.com** → sign in → **New repository** → name it `the-work` → **Create**.
2. Click **uploading an existing file**.
3. Drag in **all** files from this folder: `index.html`, `manifest.json`,
   `schema.sql`, `icon-192.png`, `icon-512.png`, `SETUP.md`.
4. **Commit changes**.

---

## Part 4 — Publish with Netlify

1. **netlify.com** → **Sign up** → **Sign up with GitHub**.
2. **Add new site** → **Import an existing project** → **GitHub** → pick `the-work`.
3. Leave build settings blank (no build step), click **Deploy**.
4. You get a live URL like `https://the-work-xyz.netlify.app`. Rename under
   **Site settings → Change site name**, or add your own domain later.

Any time you change the code, re-upload it to GitHub — Netlify republishes within
a minute.

---

## Part 5 — First run

1. Open your Netlify URL.
2. **You**: Create one → sign up as **Player**.
3. **Coach**: send them the same URL → they sign up as **Coach**.
4. Coach → **Players** tab → enter the email you used → **Link**.
5. Coach → **Drills** tab → add drills. Fill in the defaults (time, balls,
   distance, mental, physical, why, goal) — these are what auto-fill in the sheet.
   Your spreadsheet's drill list is the source to copy from.
6. Either of you opens **The Sheet**:
   - Pick a **Day** at the top (coach also picks which **Player**).
   - In each row, choose a **Drill** — club, category, distance, defaults and goal
     fill in. Type over Time / Balls / Mental / Physical with the real numbers.
   - **Player** ticks **Done**, adds **Completed notes**; both can use **Notes**.
   - **+ Add row** for the next drill. **Save the day** writes it to the cloud.
7. **Progress** shows category balance over the last 7 days (coach can pick a player).

---

## Install like an app (optional)

Open the URL on a phone, then:
- **iPhone (Safari)**: Share → **Add to Home Screen**
- **Android (Chrome)**: menu → **Install app**

Opens full-screen with its own icon — no app store.

---

## What each file is

| File | Does |
|---|---|
| `index.html` | The whole app |
| `schema.sql` | Run once in Supabase to build the database |
| `manifest.json` | Home-screen install |
| `icon-192.png` / `icon-512.png` | App icons |
| `SETUP.md` | This guide |

---

## How the sheet behaves

- **Auto-filled (grey) cells**: Club, Category, Distance, Why, Goal — pulled from
  the drill you pick. Reference only.
- **Editable cells**: Time, Balls, Mental, Physical — start from the drill's
  defaults, type over them with what actually happened.
- **Done / Completed notes**: the player's to fill (read-only for the coach).
- **Notes**: free text, either side can write.
- **Totals** row recalculates as you type.
- **Save the day** stores every row against that player + date. Re-open any day to
  see or edit it.

---

## Common snags

- **"No player with that email"** — the player must sign up first, and the coach
  must type the exact email used.
- **Nothing after signup** — refresh once; the profile is created a moment later.
- **Grid drills empty** — add drills in the **Drills** tab first.
- **Changes not showing** — re-upload the edited `index.html` to GitHub; Netlify
  deploys from GitHub, not your computer.

---

## Grow it next

- Coach dashboard: completed-vs-assigned across all players.
- Calibration columns (drill/time/balls) if you want them back in the grid.
- Link days to tournament dates; pull in HRV / sleep alongside practice load.

The database is already built to support these.
