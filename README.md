# 3D SameGame: Cube Edition

A three-dimensional tile-matching puzzle game played on a 12×12×12 cubic grid with gravity directed toward the center.

## Features

- **12×12×12 3D Grid**: 1,728 cubes in a fully 3D playing field
- **Center-Directed Gravity**: Unique gravity system where blocks fall inward from all six faces toward the center
- **5 Colors**: Carefully chosen contrasting colors for easy differentiation
- **Intuitive Controls**:
  - Drag to rotate the cube
  - Hover to preview clearable groups
  - Click to clear groups (2+ connected cubes)
  - Scroll to zoom
- **Smart Scoring**: Rewards large clears, penalizes small ones - (n - 2)² - 5n formula
- **Visual Feedback**:
  - Highlight preview of clearable groups
  - Smooth animations for clearing and gravity
  - Real-time score and move tracking

## How to Play

1. **Open in Godot**: Open the project in Godot 4.x (tested with Godot 4.3)
2. **Run**: Press F5 or click the Play button
3. **Rotate**: Click and drag to rotate the entire cube to view all faces
4. **Select**: Hover over cubes to see which groups can be cleared (minimum 2 cubes)
5. **Clear**: Click to clear highlighted groups
6. **Strategy**: Plan ahead! The scoring rewards patience:
   - 2 cubes = **-10 points** (penalty!)
   - 3 cubes = **-14 points** (penalty!)
   - 4 cubes = **-16 points** (penalty!)
   - 5 cubes = **-16 points** (penalty!)
   - 6 cubes = **-14 points** (penalty!)
   - 7 cubes = **-10 points** (penalty!)
   - 8 cubes = **-4 points** (penalty!)
   - 9 cubes = **4 points** (first positive!)
   - 10 cubes = **14 points**
   - 15 cubes = **94 points**
   - 20 cubes = **224 points**

## Game Rules

### Adjacency
Two cubes are adjacent if they share a complete face (not just an edge or corner). Each cube can have up to 6 neighbors.

### Clearing
- Minimum of 2 adjacent same-colored cubes required
- All connected cubes of the same color are cleared together
- Scoring formula: `(n - 2)² - 5n` where n is the number of cubes cleared
  - Small clears are **penalized** with negative points
  - Large clears are **rewarded** with positive points
  - Break-even point: 9 cubes (4 points)
  - Strategic depth: save small groups to build bigger combos!

### Gravity
After cubes are cleared, remaining cubes fall toward the center point (5.5, 5.5, 5.5):
- Cubes on the left side fall right (toward center)
- Cubes on the right side fall left (toward center)
- Same logic applies for all three axes

### Game Over
The game ends when no valid moves remain (no groups of 2+ adjacent same-colored cubes exist).

## Project Structure

```
3dsamegame/
├── project.godot          # Godot project configuration
├── scenes/
│   └── Main.tscn         # Main game scene
├── scripts/
│   ├── Main.gd           # Scene initialization
│   ├── Grid3D.gd         # Grid logic, adjacency, gravity
│   ├── GameManager.gd    # Game flow, input, scoring
│   └── CameraController.gd # 3D camera rotation
├── icon.svg              # Project icon
└── README.md             # This file
```

## Technical Details

- **Engine**: Godot 4.5+ (GL Compatibility mode)
- **Resolution**: 3840×2160 (4K native) with resizable window
- **Anti-aliasing**: MSAA 4x + FXAA for smooth edges
- **Performance**: Optimized for 60 FPS with smooth animations
- **Physics**: Uses Godot's built-in physics for raycasting (hover detection)
- **Camera**: Quaternion-based trackball rotation (no gimbal lock)

## Strategy Tips

1. **Patience is key**: Small clears are **heavily penalized** - you need 9+ cubes to get positive points!
2. **Avoid small groups**: Clearing 2-8 cubes will **cost you points** - resist the temptation!
3. **Build combos**: Use gravity strategically to merge small groups into larger ones before clearing
4. **Plan ahead**: Consider how gravity will redistribute cubes after clearing
5. **Center advantage**: Clearing cubes near the center can create larger groups as outer cubes fall inward
6. **Rotate often**: View from all angles to find the biggest groups
7. **Risk vs reward**: Sometimes taking a -10 point penalty is worth it to prevent getting stuck

## Future Enhancements

Potential features to add:
- Difficulty levels (4-6 colors, different grid sizes)
- Particle effects for clearing
- Sound effects and music
- High score persistence
- Undo functionality
- Hint system
- Complete clear bonus (10,000 points)
- Color-blind mode with patterns/symbols

## License

This is a reference implementation based on the 3D SameGame specification. Feel free to modify and extend!

---

**Enjoy the game!** 🎮
