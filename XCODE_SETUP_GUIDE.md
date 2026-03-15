# FitLock — Xcode Setup Guide (Tracker Mode)

This version runs as a fitness tracker + weight management app (no app blocking).
App blocking requires a paid Apple Developer account ($99/year) and will be added later.

Every instruction tells you exactly where to click in Xcode.

---

## BEFORE YOU START

- Plug your iPhone into your Mac via USB cable
- On your iPhone: **Settings > Privacy & Security > Developer Mode > ON** (phone will restart)
- After restart, confirm the Developer Mode prompt on your phone
- When your phone asks "Trust This Computer?" tap **Trust** and enter your passcode
- Make sure your Mac has internet access (Xcode needs to talk to Apple's servers)

---

## STEP 1: Create the Xcode Project

1. Open Xcode
2. **Top menu bar** (the bar at the very top of your screen): click **File > New > Project...**
3. A template picker window appears:
   - **Top row of tabs** in this window: click **iOS** (not macOS, watchOS, etc.)
   - In the grid of icons below, click **App** (first icon)
   - Click **Next** (bottom-right corner of this window)
4. A form appears. Fill it in:
   - **Product Name**: `FitLock`
   - **Team**: Click the dropdown, select **Neel Vinay (Personal Team)**
   - **Organization Identifier**: `com.fitlock`
   - **Bundle Identifier**: auto-fills to `com.fitlock.FitLock` — leave it
   - **Interface**: make sure **SwiftUI** is selected in the dropdown
   - **Language**: make sure **Swift** is selected
   - **Storage**: None
   - **Uncheck** "Include Tests" if it's checked
   - Click **Next**
5. A Finder window asks where to save. Navigate to:
   ```
   /Users/neelvinay/Desktop/project_health
   ```
   Click **Create**

---

## STEP 2: Select Your iPhone as the Build Device

Look at the **top center of the Xcode window**. You'll see a bar like:

```
[▶ Play] [■ Stop]    FitLock > Any iOS Device (arm64)
```

1. Click the part that says **Any iOS Device (arm64)** (or whatever device text is there)
2. A dropdown menu appears
3. Under the section labeled **iOS Devices**, you should see your iPhone's name
4. Click your iPhone's name to select it

**If you don't see your iPhone:**
- Make sure USB cable is connected
- Top menu bar: **Window > Devices and Simulators** — this opens a window showing connected devices
- If your phone appears there but says "Preparing" — wait a few minutes
- If it says "Developer Mode disabled" — go back to the BEFORE YOU START section

---

## STEP 3: Add Capabilities

### How to get to the right screen:

1. Look at the **left sidebar** (the panel on the left side of Xcode). At the top you'll see a row of small icons. Click the **first icon** (looks like a folder) — this is the **Project Navigator** (keyboard shortcut: **Cmd+1**)
2. In the Project Navigator, at the very top, click the **blue icon labeled "FitLock"** — this is your project file
3. The middle area of Xcode changes to show project settings. You'll see two columns:
   - Left column has **PROJECT** (with "FitLock" under it) and **TARGETS** (with "FitLock" under it)
   - Click **FitLock** under **TARGETS**
4. Now look at the **top tab bar** in the middle editor area. You'll see these tabs:
   ```
   General | Signing & Capabilities | Resource Tags | Info | Build Settings | Build Phases | Build Rules
   ```
5. Click **Signing & Capabilities**

### Verify Signing Works:

- "Automatically manage signing" should be **checked** (it has a checkbox)
- **Team** dropdown should show: **Neel Vinay (Personal Team)**
- **Bundle Identifier**: `com.fitlock.FitLock`
- If there are yellow warning triangles, click the **Try Again** button
- With your phone connected and internet working, the warnings should clear

### Add HealthKit Capability:

1. At the top-left of the editor area (just below the tab bar), you'll see a button that says **+ Capability**
2. Click it — a popup search window appears
3. Type `HealthKit` in the search field
4. Double-click **HealthKit** in the results
5. A new **HealthKit** section appears in the capabilities list
6. Inside that section, you'll see a checkbox: **Background Delivery** — check it

### Add Background Modes Capability:

1. Click **+ Capability** again (same button, top-left area)
2. Type `Background` in the search
3. Double-click **Background Modes**
4. A new section appears with several checkboxes. Check these two:
   - ✅ **Background fetch**
   - ✅ **Background processing**
   - Leave all others unchecked

**That's it for capabilities.** You only need HealthKit and Background Modes. No Family Controls, no App Groups.

---

## STEP 4: Set iOS Version to 17

1. You should still be looking at the **FitLock** target settings
2. Click the **General** tab (first tab in the top tab bar of the editor)
3. Near the top, find **Minimum Deployments**
4. There's a dropdown next to "iOS" — click it and select **17.0**

---

## STEP 5: Add Info.plist Entries

1. Still looking at the **FitLock** target
2. Click the **Info** tab (4th tab in the top tab bar: General | Signing & Capabilities | Resource Tags | **Info** | ...)
3. You'll see a section called **Custom iOS Target Properties** — it's a table of Key/Value rows
4. Hover your mouse over any existing row — a **+** button appears on the right side of the row
5. Click **+** to add a new row
6. In the Key column, start typing `Privacy - Health Share Usage Description`
   - Xcode will auto-suggest it — select it from the dropdown
7. The Type column should say **String**
8. In the Value column, type:
   ```
   FitLock reads your steps, active calories, and weight data to track your daily fitness goals and weight journey.
   ```

Now add the background task identifiers:

9. Click **+** to add another row
10. Type `Permitted background task scheduler identifiers` (Xcode will auto-suggest `BGTaskSchedulerPermittedIdentifiers`)
11. The Type should be **Array**
12. Click the **triangle** next to it to expand the array
13. Click the **+** that appears to add Item 0
14. Set Item 0's value to: `com.fitlock.goalcheck`
15. Click **+** again to add Item 1
16. Set Item 1's value to: `com.fitlock.healthkit.refresh`

---

## STEP 6: Delete the Default Template Files

Xcode auto-created two files we don't need (our repo has replacements).

1. In the **left sidebar** (Project Navigator — **Cmd+1**), expand the **FitLock** folder (yellow folder icon)
2. You'll see **ContentView.swift** — right-click it > **Delete** > click **Move to Trash**
3. You'll see **FitLockApp.swift** — right-click it > **Delete** > click **Move to Trash**

---

## STEP 7: Add All the Source Files

1. In the **left sidebar**, right-click the **FitLock** yellow folder
2. Choose **Add Files to "FitLock"...**
3. A Finder window opens. Navigate into:
   ```
   /Users/neelvinay/Desktop/project_health/FitLock/FitLock/
   ```
4. You should see these 5 folders: `App`, `Models`, `Services`, `Views`, `Utilities`
5. **Select all 5 folders** (click the first one, then hold **Cmd** and click each of the others)
6. At the bottom of the dialog, verify these settings:
   - ✅ **Copy items if needed** — CHECKED
   - ◉ **Create groups** — selected (not "Create folder references")
   - Under **Add to targets**: only **FitLock** should be checked ☑️
7. Click **Add**

### Verify Files Were Added:

After adding, expand the folders in the left sidebar. You should see:
```
📁 FitLock
  📁 App
    📄 FitLockApp.swift
    📄 AppState.swift
  📁 Models
    📄 FitLockGoals.swift
    📄 UserProfile.swift
    📄 DailyProgress.swift
    📄 WeeklyWeightRecord.swift
    📄 AdaptationCheckpoint.swift
    📄 WeightProjectionPoint.swift
  📁 Services
    📄 GoalStorage.swift
    📄 HealthKitManager.swift
    📄 MetabolismCalculator.swift
    📄 WeightManager.swift
    📄 GoalChecker.swift
    📄 NotificationManager.swift
    📄 BackgroundTaskManager.swift
  📁 Views
    📁 Onboarding
      📄 OnboardingContainerView.swift
      📄 PermissionsStepView.swift
      📄 ActivityGoalsStepView.swift
      📄 UserProfileStepView.swift
      📄 WeightGoalStepView.swift
    📁 Dashboard
      📄 DashboardView.swift
      📄 ActivityProgressView.swift
      📄 WeightProgressView.swift
      📄 LockStatusBanner.swift
    📁 Weight
      📄 WeightEntryView.swift
      📄 WeightHistoryView.swift
      📄 ProjectionChartView.swift
      📄 WeightDashboardView.swift
    📁 Settings
      📄 SettingsView.swift
      📄 ActivitySettingsView.swift
      📄 WeightSettingsView.swift
    📁 Components
      📄 ProgressRing.swift
      📄 GoalCard.swift
      📄 WeightTrendChart.swift
  📁 Utilities
    📄 Constants.swift
    📄 DateHelpers.swift
    📄 UnitConverter.swift
```

If any files show up in **red text** — right-click > Delete (Remove Reference), then re-add them.

---

## STEP 8: Build

1. At the top of Xcode, make sure it says: **FitLock > [Your iPhone Name]**
2. Press **Cmd+B** (or top menu bar: **Product > Build**)
3. Look at the **top center status bar** — it will say "Building..." then either:
   - ✅ **"Build Succeeded"** — move to Step 9
   - ❌ **"Build Failed"** — see the errors below

### If Build Fails:

To see the errors:
1. In the **left sidebar**, click the **triangle/warning icon** (4th icon in the icon row) — this is the **Issue Navigator** (keyboard shortcut: **Cmd+5**)
2. You'll see a list of red (errors) and yellow (warnings) items
3. Click on any error to see which file and line it's on

**Common errors and fixes:**

| Error | Fix |
|---|---|
| `Cannot find type 'X' in scope` | A file wasn't added to the correct target. Click the file in the sidebar, then in the **right sidebar** (**Cmd+Option+1**), scroll to **Target Membership** and check **FitLock** |
| `Multiple commands produce` or duplicate symbols | You didn't delete the auto-generated files in Step 6, or duplicate folders were created. Delete `ContentView.swift`, the original `FitLockApp.swift`, and any folders named `App 2`, `Services 2`, etc. |
| `Signing for "FitLock" requires a development team` | Go to Signing & Capabilities tab and select your team |
| `No such module 'HealthKit'` | Make sure HealthKit capability was added in Step 3 |

---

## STEP 9: Run on Your Phone

1. Make sure your iPhone is connected and selected as the device (top bar)
2. Press **Cmd+R** (or top menu bar: **Product > Run**)
3. Xcode builds and installs the app on your phone

**First-time trust required:**
- If your phone shows "Untrusted Developer" when you try to open the app:
  1. On your iPhone: **Settings > General > VPN & Device Management**
  2. Tap your developer certificate (shows your Apple ID email)
  3. Tap **Trust** > confirm

**The app should now launch on your phone!**

---

## HOW TO CHECK TARGET MEMBERSHIP OF ANY FILE

If a file isn't being found during build, check which target it belongs to:

1. Click the file in the **left sidebar**
2. Show the **right sidebar**: click the rightmost icon in the top-right toolbar, or press **Cmd+Option+0**
3. In the right sidebar, click the **first tab icon** (File Inspector) or press **Cmd+Option+1**
4. Scroll down to **Target Membership**
5. Only **FitLock** should be checked ☑️

---

## XCODE LAYOUT REFERENCE

```
┌──────────────────────────────────────────────────────────────────┐
│  TOP MENU BAR: File  Edit  View  Navigate  Find  Product  ...   │
├───────────────────────────────────────────────────────────────── │
│  TOOLBAR: [▶][■]  [Scheme > Device]           [Status]  [⊞][⊟] │
├──────┬──────────────────────────────────────────────┬────────── │
│      │                                              │           │
│  L   │   EDITOR AREA                                │   R      │
│  E   │                                              │   I      │
│  F   │   When a file is selected:                   │   G      │
│  T   │     Shows code                               │   H      │
│      │                                              │   T      │
│  S   │   When project/target is selected:           │          │
│  I   │     Shows settings with tabs:                │   S      │
│  D   │     General | Signing & Capabilities |       │   I      │
│  E   │     Resource Tags | Info |                   │   D      │
│  B   │     Build Settings | Build Phases |          │   E      │
│  A   │     Build Rules                              │   B      │
│  R   │                                              │   A      │
│      │                                              │   R      │
├──────┴──────────────────────────────────────────────┴──────────│
│  BOTTOM PANEL (toggle: Cmd+Shift+Y)                            │
│  Debug console — shows print() output when the app is running  │
└──────────────────────────────────────────────────────────────────┘

LEFT SIDEBAR TABS (row of icons at the top of the left panel):
  📁 Cmd+1 = Project Navigator    (your files — THIS IS WHERE YOU SPEND MOST TIME)
  🔍 Cmd+3 = Find Navigator       (search across all files)
  ⚠️  Cmd+5 = Issue Navigator      (build errors and warnings)
  🔴 Cmd+8 = Breakpoint Navigator (debugging)

RIGHT SIDEBAR TABS (row of icons at the top of the right panel):
  📄 Cmd+Option+1 = File Inspector      (file path, target membership)
  ❓ Cmd+Option+3 = Quick Help Inspector (documentation for selected code)
```

---

## 7-DAY RE-SIGNING

Your free account means the app stops working after 7 days. To refresh:

1. Plug in iPhone
2. Open this project in Xcode
3. Press **Cmd+R**
4. Done — good for another 7 days

The app sends a reminder notification on day 6.

---

## TESTING CHECKLIST

Once the app is running on your phone:

- [ ] Onboarding screens appear (4 steps)
- [ ] HealthKit permission dialog pops up — tap Allow All
- [ ] Notification permission appears — tap Allow
- [ ] You can set step and calorie goals
- [ ] You can enter weight/height/age
- [ ] You can set a weight goal and pace
- [ ] Dashboard shows real step count from Apple Watch
- [ ] You can log a weight entry
- [ ] Weight projection chart renders
- [ ] Status banner shows goal progress

---

## WHEN YOU GET A PAID DEVELOPER ACCOUNT

To add app blocking later ($99/year Apple Developer Program):

1. Add Family Controls capability to the main target
2. Add two extension targets (Device Activity Monitor + Shield Configuration)
3. Re-add ScreenTimeManager.swift and related files
4. Update GoalChecker to apply/remove shields
5. Add the app selection step back to onboarding
