# User Guide for Remote Team Members

This guide explains how to use the Exhibition Buyer Collaboration app as a **remote team member** providing support to on-site buyers.

---

## Overview

As a remote team member, you will:
1. Join your buyer's team using an invite code
2. View photos and product flags from the exhibition floor
3. Enter pricing information and conversions
4. Provide purchasing recommendations
5. Collaborate in real-time with on-site buyers

---

## Step 1: Registration and Joining the Team

### 1.1 Register Your Account

1. Open the app in your web browser (desktop or mobile)
   - Production URL: https://exhibition-buyer-app.pages.dev
2. Tap/click **"Register"** on the login screen
3. Enter your email and password
4. Tap **"Register Account"**
5. You will be automatically logged in

### 1.2 Join Your Buyer's Team

**You need two pieces of information from your on-site buyer:**
- **Invite Code** (6 uppercase letters, e.g., "A3F8B1")
- **Team Password**

**To join:**

1. After registration, you'll see the Event Selection screen
2. Tap the **"Switch Team"** button in the team header bar
3. Select **"Join Team"** from the bottom sheet
4. Enter:
   - **Team Name or Invite Code**: Use the 6-digit code
   - **Team Password**: Enter the password provided by your buyer
5. Tap **"Verify & Join"**
6. Success! You'll now see all events created by your team

**Important**: Teams are completely isolated for privacy. You can only see data from teams you've joined.

---

## Step 2: Understanding the Interface

### 2.1 Event Selection Screen

After joining a team, you'll see:
- **Team Header**: Shows current team name and invite code
  - Tap the **copy icon** to copy the invite code
- **Online Users**: Green dots show who's currently active
- **Event List**: All exhibitions created by your on-site buyers
  - The **active event** is highlighted in green with "Current" badge

### 2.2 Navigation Flow

```
Event Selection
    ↓ (tap event)
Booth List
    ↓ (tap booth)
Photo Gallery
    ↓ (tap photo)
Photo Detail with Flags
```

---

## Step 3: Viewing Exhibition Data

### 3.1 Select an Event

1. On the **Event Selection** screen, tap any event card
2. This shows all booths for that exhibition
3. Each booth card displays:
   - Booth number (e.g., "001", "A15")
   - Cover photo (if buyer captured one)
   - Photo count

### 3.2 Browse Booths

1. The **Booth List** shows all booths in a grid layout
2. Tap a booth card to view its photos
3. Look for booths with higher photo counts - these need your attention first

### 3.3 View Photos and Flags

1. In the **Photo Gallery**, you'll see all product photos
2. Photos with flags show a **flag counter** (e.g., "3 flags")
3. Tap a photo to see flag details
4. **Zoom and pan**: Use pinch gestures to examine products closely

---

## Step 4: Working with Product Flags

### 4.1 Understanding Flags

Each flag represents one product marked by the on-site buyer:
- **Flag Number**: Sequential identifier (1, 2, 3...)
- **Crosshair Position**: Shows exact product location on photo
- **Pricing Fields**: Where you enter price information

**Note**: Flags are managed by the on-site buyer. Remote team members can view and edit flag data (prices, recommendations) but cannot create or delete flags.

### 4.2 Flag Information Panel

Below each photo, you'll see a list of flags with columns:
- **No.**: Flag number
- **Seller Price (¥)**: RMB price from supplier (you enter this)
- **Converted Price**: Auto-calculated based on team formula
- **Target Price**: Your company's target price (you enter this)
- **Remote Decision**: Your recommendation (Purchased/Sold Out)

---

## Step 5: Entering Price Information

### 5.1 Enter Seller Price (RMB)

1. Tap the **"Seller Price"** field for a flag
2. Enter the price quoted by the supplier in RMB
3. Tap outside or press Enter to save
4. **Converted Price** updates automatically using your team's formula

**Example**: If seller price is ¥675 and formula is `RMB/6.75`, converted price = $100

### 5.2 Enter Target Price

1. Tap the **"Target Price"** field
2. Enter your company's target price for comparison
3. This helps the buyer see if the seller price meets your targets
4. The buyer can quickly compare: Converted Price vs Target Price

### 5.3 Real-Time Calculation

- Price conversions happen instantly as you type
- The buyer sees updates in real-time on their device
- Use your team's formula for consistent pricing across all products

---

## Step 6: Setting Up Price Conversion Formula

### 6.1 Access Formula Settings

1. Go back to **Event Selection** screen
2. Tap the **Settings icon** (top right)
3. Select **"Formula Settings"**

### 6.2 Create/Update Formula

Your team can set a custom formula for price conversion:

**Common formula examples**:
- Simple exchange rate: `RMB/6.75`
- After deducting fees: `(RMB - 50)/6.75`
- With fixed shipping: `RMB/6.75 + 10`
- Complex calculation: `(RMB * 0.95)/7.0 + 5`

**Formula rules**:
- Use `RMB` as the variable for seller price
- Supported operators: `+`, `-`, `*`, `/`, `(`, `)`
- Preview shows results for sample prices (100, 500, 1000 RMB)

### 6.3 Formula Preview

Before saving, check the preview:
- Enter different RMB values
- Verify the converted prices make sense
- Ensure formula logic is correct

---

## Step 7: Making Recommendations

### 7.1 Remote Decision Options

After reviewing prices and product photos, you can recommend:

1. **Purchased** ✓
   - Product meets criteria
   - Price is acceptable
   - Recommend buyer to purchase

2. **Sold Out** ✗
   - Product unavailable
   - Buyer should skip

3. **No Decision** (blank)
   - Need more information
   - Buyer will decide on-site

### 7.2 How to Set Recommendations

1. Tap the **"Remote Decision"** dropdown for a flag
2. Select your recommendation
3. The buyer sees this immediately in their flag list
4. Recommendations show as colored indicators in the buyer's view

---

## Step 8: Real-Time Collaboration

### 8.1 Monitor Online Users

- The **Event Selection** screen shows online team members
- Green dots indicate active users
- See who's currently working in real-time

### 8.2 Data Synchronization

All changes sync automatically across devices:
- New photos appear within seconds
- Price updates show immediately
- Flag additions are instant
- No manual refresh needed

### 8.3 Team Collaboration Workflow

**Recommended workflow**:

1. **Morning briefing**: Buyer creates event and booths
2. **On-site capture**: Buyer takes photos and adds flags throughout the day
3. **Remote processing**: You continuously monitor new photos and enter prices
4. **Instant feedback**: Buyer sees your recommendations in real-time
5. **Evening review**: Team discusses products that need final decisions

---

## Step 9: Best Practices for Remote Support

### 9.1 Efficiency Tips

1. **Work sequentially**: Process flags in order (Flag 1, 2, 3...)
2. **Batch similar products**: Enter prices for all similar items at once
3. **Use formula wisely**: Set up formula first to save calculation time
4. **Check target prices**: Always enter target price for buyer comparison
5. **Clear recommendations**: Only mark as "Purchased" if you're confident

### 9.2 Communication Guidelines

1. **Response time**: Try to process new photos within 5-10 minutes
2. **Clarifications**: If photo is unclear, contact buyer via phone/chat
3. **Complex items**: Leave blank if you need buyer's on-site judgment
4. **Price verification**: Double-check calculations for high-value items

### 9.3 Quality Control

1. **Verify conversions**: Check formula results make sense
2. **Compare products**: Look at similar flags across photos
3. **Flag anomalies**: Alert buyer to unusual pricing
4. **Track progress**: Monitor photo count vs processed flags

---

## Step 10: Managing Multiple Events

### 10.1 Switch Between Events

1. Return to **Event Selection** screen
2. Tap any event card to switch contexts
3. Active event is highlighted for easy identification

### 10.2 Historical Data

- All events remain accessible after completion
- View past exhibition data for reference
- Compare pricing across different events/seasons

---

## Desktop vs Mobile Browser Experience

### Desktop Advantages

- **Larger screen**: See more photos and flags simultaneously
- **Keyboard input**: Faster price entry
- **Multi-tasking**: Keep app open alongside spreadsheets/tools
- **Grid layout**: Up to 5 columns of booths

### Mobile Browser

- **Responsive design**: 3-column grid on phones
- **Touch-friendly**: Large tap targets for price fields
- **Flexibility**: Work from anywhere
- **Same features**: Full functionality on mobile web

---

## Troubleshooting

### Can't See New Photos?

1. **Check team**: Ensure you're in the correct team
2. **Verify event**: Make sure you're viewing the active event
3. **Refresh**: Pull down to refresh the screen
4. **Connection**: Check your internet connection

### Formula Not Calculating?

1. **Syntax check**: Ensure formula uses correct operators
2. **RMB variable**: Must use uppercase "RMB"
3. **Test preview**: Use preview to verify formula works
4. **Save changes**: Don't forget to save after editing

### Lost Invite Code?

1. The invite code is visible in the **team header bar**
2. Tap the **copy icon** to copy it
3. Share it with new team members who need to join

### Need to Join a Different Team?

1. Tap **"Switch Team"** button
2. Select **"Join Team"**
3. Enter the new team's invite code and password
4. Your previous team data remains accessible

---

## Privacy and Security

### Team Isolation

- **Complete privacy**: Each team's data is isolated
- **No cross-team visibility**: You can only see your team's events
- **Secure access**: Invite code + password required to join

### Data Access

- **Real-time sync**: All team members see the same data
- **No data loss**: All changes are immediately saved to cloud
- **Persistent**: Data persists across sessions and devices

---

## Quick Reference

| Task | Location | Action |
|------|----------|--------|
| Join Team | Event Selection → Switch Team | Enter invite code + password |
| View Event | Event Selection | Tap event card |
| Enter Price | Photo Detail → Flag List | Tap price field, enter value |
| Set Formula | Settings → Formula Settings | Create/edit formula |
| Make Recommendation | Photo Detail → Remote Decision | Select Purchased/Sold Out |
| Copy Invite Code | Team Header | Tap copy icon |
| Check Online Users | Event Selection | Below team header |

---

## Keyboard Shortcuts (Desktop)

- **Tab**: Navigate between price fields
- **Enter**: Save current field and move to next
- **Ctrl + Z**: Undo last change (browser default)
- **F5**: Refresh page to force sync check

---

## Formula Examples Library

### Basic Exchange Rates
```
RMB/6.75          # Simple USD conversion
RMB/7.0           # Conservative rate
RMB/6.5           # Aggressive rate
```

### Deduct Fees
```
(RMB - 50)/6.75   # Deduct ¥50 flat fee
RMB * 0.95/6.75   # Deduct 5% commission
```

### Add Costs
```
RMB/6.75 + 10     # Add $10 shipping per item
RMB/6.75 + RMB*0.1  # Add 10% handling fee
```

### Complex Formulas
```
(RMB - 100) * 0.9 / 7.0 + 15
# Deduct ¥100, apply 10% discount, convert at 7.0, add $15 overhead
```

---

## Support

For technical issues or questions:
- **GitHub Issues**: https://github.com/martinyyang/exhibition-buyer-app/issues
- **Team Leader**: Contact your on-site buyer for team-specific questions
- **Documentation**: Check project README for deployment details

---

## System Requirements

### Browser Compatibility
- **Chrome**: v90+ (recommended)
- **Firefox**: v88+
- **Safari**: v14+
- **Edge**: v90+

### Network Requirements
- **Minimum**: 3G connection
- **Recommended**: 4G/WiFi for optimal experience
- **Offline**: Limited functionality, syncs when reconnected

---

*Last updated: 2026-08-09*
