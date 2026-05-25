# ⚔️ Combat System

R6-based combat system developed for Roblox.

## Features

- Combo system (4 hit combination)
- Block mechanic
- Dash system (W/A/S/D directional)
- Ragdoll & UnRagdoll system
- Hitbox system
- Animation manager

## Setup

**Requirements:**
- [Rojo](https://rojo.space) 7.6.1+
- Roblox Studio

**Steps:**
```bash
git clone https://github.com/Yusuf-Hikmet/Combat.git
cd Combat
rojo serve
```

Then connect via the Rojo plugin in Roblox Studio.

## Project Structure

src/
├── server/          → Server-side scripts
├── replicated/      → Shared modules
├── replicatefirst/  → First-loaded scripts
└── starterps/       → Client scripts