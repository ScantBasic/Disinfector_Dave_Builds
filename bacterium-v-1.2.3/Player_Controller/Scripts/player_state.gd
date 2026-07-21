extends State
class_name PlayerState

const IDLE = "Idle"
const RUNNING = "Running"
const JUMPING = "Jumping"
const FALLING = "Falling"
const DOUBLEJUMPING = "DoubleJumping"
const DASHING = "Dashing"
const SLIDING = "Sliding"
const WALLRUNNING = "WallRunning"
const WALLJUMPING = "WallJumping"
const WADING = "Wading"
const SWIMMING = "Swimming"


var player : PlayerCharacter

func _ready() -> void:
	await owner.ready
	player = owner as PlayerCharacter
	assert(player != null, "The PlayerState State type must be used only in the player scene.
	It needs the owner to be a player node")
