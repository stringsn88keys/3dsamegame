# 3D SameGame: Cube Edition - Implementation Documentation

## Overview
A three-dimensional tile-matching puzzle game implemented in **Godot 4.5**, played on a 12×12×12 cubic grid with gravity directed toward the center, creating a unique spatial challenge where blocks fall inward from all six faces.

**Status**: Fully implemented and playable
**Engine**: Godot 4.5 (GL Compatibility renderer)
**Platform**: Desktop (macOS tested, cross-platform compatible)
**Resolution**: Native 4K (3840×2160) with anti-aliasing

## Playing Field

### Structure
- **Dimensions**: 12×12×12 cube (1,728 total positions)
- **Initial State**: All positions filled with randomly colored cubes
- **Color Count**: 4-5 different colors (configurable for difficulty)
- **Gravity Direction**: Toward the geometric center of the 12×12×12 cube from all six faces

### Coordinate System
- Use 3D coordinates (x, y, z) where each ranges from 0-11
- Center of cube is at (5.5, 5.5, 5.5)
- Each face of the outer cube acts as a "floor" for gravity purposes

## Controls

### Rotation
- **Click/Drag** (desktop): Rotate the entire cube field in 3D space
- **Implementation**: Quaternion-based trackball/arcball controls (eliminates gimbal lock)
- **Horizontal drag**: Rotates around world Y-axis (up)
- **Vertical drag**: Rotates around camera's local right axis
- **Smooth wrapping**: Can rotate continuously in all directions without hitting limits
- **Speed**: 0.003 rotation sensitivity (configurable)
- **Drag detection**: 5-pixel threshold to distinguish clicks from drags

### Selection
- **Hover** (desktop): Real-time preview which cubes would be cleared
  - Uses physics raycasting to detect cube under mouse cursor
  - The hovered cube and all connected same-color neighbors highlight with emission glow
  - Only highlights if 2+ cubes would be cleared
  - Live preview shows: "Cubes: X | Points: ±Y" with new scoring formula
  - Preview updates immediately as mouse moves

- **Click-to-Clear**: Clear the highlighted group on mouse button **release** (not press)
  - Only triggers if mouse didn't move >5 pixels (wasn't a drag)
  - Prevents accidental clears while rotating camera
  - Minimum 2 cubes required

### Camera
- **Zoom**: Scroll wheel zooms in/out (15-35 units distance)
- **Lighting**: Two directional lights attached to camera (main + fill) that rotate with view
- **Initial position**: Starts at 25 units distance, rotated 45° horizontal, -30° vertical

## Adjacency Rules

### Connection Definition
Two cubes are considered **adjacent** if they share a complete face (not just an edge or corner).

In 3D coordinates, cube at (x₁, y₁, z₁) is adjacent to cube at (x₂, y₂, z₂) if:
- Exactly one coordinate differs by 1, and
- The other two coordinates are identical

**Each cube has up to 6 adjacent neighbors** (fewer at boundaries):
- (x±1, y, z)
- (x, y±1, z)
- (x, y, z±1)

### Clearing Requirements
- **Minimum group size**: 2 cubes of the same color sharing a face
- All cubes in a connected group are cleared simultaneously
- Connection is transitive: A-B-C forms one group if all are the same color

## Gravity Mechanics

### Gravity Direction
Gravity pulls toward the center point (5.5, 5.5, 5.5) from all directions:

- **For x < 6**: Cubes fall in +x direction (toward center)
- **For x > 5**: Cubes fall in -x direction (toward center)
- Similar logic for y and z axes

### Fall Behavior
After cubes are cleared:

1. **Immediate fall**: All unsupported cubes fall toward center on their respective axis
2. **Per-axis processing**: Each axis (x, y, z) is processed independently and simultaneously
3. **Column collapse**: Within each "column" (line perpendicular to a face), cubes fall until:
   - They reach another cube, or
   - They reach the "floor" (the face of the 12×12×12 cube on that axis)

### Implementation Detail
For each axis independently:
- Identify all 144 "columns" (12×12 lines perpendicular to each face pair)
- Within each column, move cubes toward the nearer face
- Process all three axes, then repeat until stable (no more movement)

**Example**: After clearing cubes:
- A cube at (10, 5, 5) would fall in the -x direction (toward x=5)
- A cube at (2, 8, 5) would fall in the +x direction and -y direction
- Movement continues until reaching another cube or the boundary

## Scoring System

### Per-Clear Scoring
When a group of n cubes is cleared:

**Score = (n - 2)² - 5n**

This formula **penalizes small clears** and **rewards large clears**, creating strategic tension:

Examples:
- 2 cubes: (2-2)² - 5(2) = 0 - 10 = **-10 points** (penalty!)
- 3 cubes: (3-2)² - 5(3) = 1 - 15 = **-14 points** (penalty!)
- 4 cubes: (4-2)² - 5(4) = 4 - 20 = **-16 points** (penalty!)
- 5 cubes: (5-2)² - 5(5) = 9 - 25 = **-16 points** (penalty!)
- 6 cubes: (6-2)² - 5(6) = 16 - 30 = **-14 points** (penalty!)
- 7 cubes: (7-2)² - 5(7) = 25 - 35 = **-10 points** (penalty!)
- 8 cubes: (8-2)² - 5(8) = 36 - 40 = **-4 points** (penalty!)
- 9 cubes: (9-2)² - 5(9) = 49 - 45 = **+4 points** (break-even point!)
- 10 cubes: (10-2)² - 5(10) = 64 - 50 = **+14 points**
- 15 cubes: (15-2)² - 5(15) = 169 - 75 = **+94 points**
- 20 cubes: (20-2)² - 5(20) = 324 - 100 = **+224 points**

*Note: This formula heavily penalizes clearing groups smaller than 9 cubes, encouraging players to build large combos through strategic gravity manipulation*

### Bonus Scoring
**Complete Clear Bonus**: If all cubes are removed from the field:
- Award bonus: **10,000 points**

**Efficiency Bonus** (optional): Based on fewest moves to complete
- Could award points based on remaining moves × 100

### Running Total
- Display current score prominently
- Show points earned for each move with animation
- Maintain high score table

## Game Flow

### Start
1. Initialize 12×12×12 field with random color distribution
2. Score starts at 0
3. Display tutorial overlay (first time only)

### During Play
1. Player rotates cube to examine all faces
2. Player hovers over cube to preview clearable groups
3. Player clicks to clear group (if valid)
4. Cleared cubes disappear with particle effect
5. Remaining cubes fall toward center according to gravity rules
6. New stable state is reached
7. Check for game over condition
8. Repeat from step 1

### Game Over Conditions
Game ends when **no valid moves remain**:
- No groups of 2+ adjacent same-colored cubes exist anywhere in the field

### End Game
1. Display final score
2. Show statistics:
   - Total cubes cleared
   - Largest single clear
   - Total moves made
   - Percentage of field cleared
3. Option to replay or return to menu
4. Update high scores if applicable

## Visual Feedback

### Cube Rendering
- **Distinct colors**: Use highly contrasting colors (e.g., red, blue, green, yellow, purple)
- **Material**: Slight transparency to see overlapping cubes
- **Edges**: Dark outlines for clarity
- **Lighting**: Directional lighting to enhance 3D perception

### Hover State
- **Emission glow**: Selected group highlights using material emission (50% of base color)
- **Real-time feedback**: Immediate visual response as mouse moves over cubes
- **Count indicator**: Display number of cubes in group (center bottom of screen)
- **Score preview**: Shows points that would be earned/lost with +/- indicator

### Clearing Animation
- **Scale-down animation**: Cubes shrink to zero over 0.25 seconds
- **Timing**: 0.3 second delay before gravity starts
- **Clean removal**: Cubes removed from scene after animation completes

### Gravity Animation
- **Smooth fall**: Cubes animate falling with bounce easing over 0.4 seconds
- **Bounce effect**: TRANS_BOUNCE easing for satisfying landing
- **Settling delay**: 0.5 second wait for all animations to complete before re-enabling input
- **Metadata updates**: Cube collision metadata updated after gravity to maintain click accuracy

## UI Elements

### HUD (Heads-Up Display) - 4K Optimized
- **Score**: 64pt font (top-left at 40,40) - displays current total score
- **Moves**: 48pt font (top-left at 40,140) - number of moves taken
- **Cubes Remaining**: 48pt font (top-left at 40,240) - live count of cubes left (updates after gravity)
- **Preview Label**: 56pt font (center-bottom) - shows "Cubes: X | Points: ±Y" when hovering
  - Only visible when hovering over valid group (2+)
  - Updates in real-time as mouse moves
  - Shows +/- to clearly indicate penalties vs rewards

### Controls Display
- **Help Label**: 42pt font (bottom-left) - Always visible
  - "Click and drag to rotate"
  - "Hover to preview"
  - "Click to clear (2+ cubes)"
  - "Scroll to zoom"

### Game Over Screen
- **Panel**: 1200×900px centered overlay with semi-transparent background
- **Title**: 96pt "Game Over!"
- **Final Score**: 72pt display
- **Moves**: 56pt display
- **Restart Button**: 56pt font - reinitializes grid and resets all counters

## Difficulty Variations

### Easy Mode
- 4 colors only
- Smaller field: 10×10×10
- More generous scoring: **(max(0, n - 2))²**
  - 2 cubes = 0 points
  - 3 cubes = 1 point
  - 4 cubes = 4 points

### Normal Mode
- 5 colors
- Standard 12×12×12 field
- Standard scoring: **(max(0, n - 3))²**
  - 2-3 cubes = 0 points
  - 4 cubes = 1 point
  - 5 cubes = 4 points

### Hard Mode
- 6 colors
- Larger field: 14×14×14
- Stricter scoring: **(max(0, n - 4))²**
  - 2-4 cubes = 0 points
  - 5 cubes = 1 point
  - 6 cubes = 4 points

### Expert Mode
- 6 colors
- 15×15×15 field
- Stricter scoring: **(max(0, n - 4))²**
- Time pressure: Points decay slowly over time

## Technical Specifications

### Implementation Details
- **Engine**: Godot 4.5 (GL Compatibility renderer)
- **Resolution**: 3840×2160 (4K native) with window mode 2 (fullscreen)
- **Anti-aliasing**:
  - MSAA 3D at 4x for smooth geometry edges
  - Screen-space AA (FXAA) for additional smoothing
  - Bilinear texture filtering
- **Frame rate**: 60 FPS target with smooth animations
- **Physics**: Godot built-in 3D physics for raycasting
  - StaticBody3D nodes for each cube with BoxShape3D collision
  - Metadata on collision bodies stores grid position for instant lookup

### Camera System
- **Type**: Quaternion-based trackball/arcball rotation
- **Benefits**: Eliminates gimbal lock, allows continuous rotation on all axes
- **Distance**: 15-35 units (starts at 25)
- **Rotation sensitivity**: 0.003 (configurable)
- **Lighting**: Two DirectionalLight3D nodes parented to camera
  - Main light: 100% energy with shadows
  - Fill light: 40% energy opposite side

### Rendering Optimizations
- **Shared mesh**: Single BoxMesh instance used for all 1,728 cubes
- **Material instances**: Duplicated materials for each color (not entire mesh)
- **Collision shapes**: 1.0 unit boxes (slightly larger than 0.9 unit visual for easier clicking)
- **Scene structure**: StaticBody3D → MeshInstance3D + CollisionShape3D hierarchy

### Data Structures
- **Grid storage**: 3D array `grid[x][y][z]` stores color indices (-1 = empty)
- **Cube references**: 3D array `cube_meshes[x][y][z]` stores StaticBody3D references
- **Adjacency**: Flood-fill algorithm with hash-based visited tracking
- **Gravity**: Multi-iteration processing per axis until stable (max 50 iterations)

### Animation Timings
- **Clear animation**: 0.25s scale-down
- **Gravity delay**: 0.3s after clear starts
- **Gravity animation**: 0.4s with EASE_OUT + TRANS_BOUNCE
- **Settling wait**: 0.5s total before input re-enabled
- **Total per-move**: ~1.0s from click to next available input

## Strategy Tips (In-Game Help)

1. **Patience is key**: Small clears are heavily penalized - you need 9+ cubes to get positive points!
2. **Avoid small groups**: Clearing 2-8 cubes will COST you points - resist the temptation!
3. **Build combos**: Use gravity strategically to merge small groups into larger ones before clearing
4. **Plan ahead**: Consider how gravity will redistribute cubes after each clear
5. **Center advantage**: Clearing cubes near the center can create larger groups as outer cubes fall inward
6. **Rotate often**: View from all angles to find the biggest groups (camera rotates smoothly in all directions)
7. **Risk vs reward**: Sometimes taking a -10 point penalty is worth it to prevent getting stuck
8. **Score breakdown**:
   - 2-8 cubes = negative points (penalty!)
   - 9 cubes = +4 points (break-even)
   - 10+ cubes = significant positive points
   - 20 cubes = +224 points!

---

## Summary of Core Rules

| Aspect | Specification |
|--------|--------------|
| **Engine** | Godot 4.5 (GL Compatibility) |
| **Resolution** | 3840×2160 (4K) with MSAA 4x + FXAA |
| **Field Size** | 12×12×12 cubes (1,728 total) |
| **Colors** | 5 contrasting colors |
| **Adjacency** | Face-sharing (6 max neighbors) |
| **Min. Clear** | 2 cubes |
| **Gravity** | Toward center from all 6 faces |
| **Scoring** | (n-2)² - 5n points (penalties below 9 cubes!) |
| **Camera** | Quaternion trackball (no gimbal lock) |
| **Win Condition** | None (high score based) |
| **Lose Condition** | No valid 2+ groups remain |
| **Controls** | Drag to rotate, mouse-up to clear (with drag detection) |
| **UI** | Score, Moves, Cubes Remaining, Live Preview |

This implementation creates a unique 3D puzzle experience with strategic depth from:
- **Center-directed gravity** system requiring spatial planning
- **Penalty-based scoring** that punishes hasty small clears
- **Smooth quaternion rotation** allowing full 360° viewing
- **Real-time feedback** showing exact point consequences before clicking
- **4K rendering** with anti-aliasing for crisp visuals
