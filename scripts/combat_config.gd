class_name CombatConfig
extends RefCounted

# Units: pixels, seconds, degrees. Fixed 60 Hz simulation.
const MAP_WIDTH: float = 2000.0
const PLAYER_SPEED: float = 180.0
const PLAYER_GRAVITY: float = 1000.0
const ANGLE_SPEED: float = 45.0
const MIN_ANGLE: float = 5.0
const MAX_ANGLE: float = 85.0
const MAX_HP: int = 100
# Terrain deformation is smaller than the damage radius. Diameter must exceed 64 px.
const CRATER_RADIUS: float = 60.0
const CRATER_SEGMENTS: int = 32
const WIND_ACCELERATION: float = 18.0
const WIND_SEED: int = 73421
const MAX_WIND: int = 5
const SHOT_LIFETIME: float = 10.0
const SHOT_BOUNDS: Rect2 = Rect2(-80, -1200, 2160, 2120)
const TRANSITION_SECONDS: float = 0.65
# Camera never shows beyond the outer walls (x -40..2040), bedrock (y 960) or shot ceiling.
const CAMERA_LIMITS: Rect2 = Rect2(-40, -1200, 2080, 2160)
# Two-tap confirmation for REINICIAR/PREPARAR during a match.
const CONFIRM_SECONDS: float = 3.0
const CONFIRM_MIN_DELAY: float = 0.25
