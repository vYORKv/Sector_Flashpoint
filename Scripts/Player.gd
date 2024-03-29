class_name Ally
extends KinematicBody2D

const ACCELERATION = 5
const FRICTION = 4
#const SPEED = 10
const TURN_SPEED = 0.2

var velocity = Vector2.ZERO
var combat_speed = true
var max_speed = 2 # Changed from 3
var reloaded = true
var can_shoot = true
var fire_rate = .5
var alliance = "red"
var hitpoints = 1
var shields = 2
var shields_active = true
var ship_id = "Player"

const BULLET = preload("res://Scenes/Objects/Bullet.tscn")
const EXPLOSION = preload("res://Scenes/Objects/ShipExplosion.tscn")

onready var TurnSpeed = $Tween
onready var Thruster = $Thruster
onready var Gun = $Gun
onready var Aim = $Aim
onready var ShootTimer = $ShootTimer
onready var ShootSFX = $ShootSFX
onready var ThrusterSFX = $ThrusterSFX
onready var BumpSFX = $BumpSFX
onready var ShipPolygon = $ShipPolygon
onready var HurtPolygon = $HurtBox/HurtPolygon
onready var ShieldArea = $ShieldArea
onready var Shield = $Shield

func _ready():
	ShootTimer.set_wait_time(fire_rate)
	ShootTimer.connect("timeout", self, "Reload")
	var poly = ShipPolygon.get_polygon() # Will need to use polygon array to set shapes for each ship on spawn

func Debug():
	pass

func Reload():
	reloaded = true
	can_shoot = true

func _input(event):
	if event.is_action_pressed("combat_speed"):
		if combat_speed == true:
			max_speed = 1.35
			combat_speed = false
			print(max_speed)
		else:
			max_speed = 3
			combat_speed = true
			print(max_speed)
	if event.is_action_pressed("shoot"):
		if can_shoot:
			Shoot()
			reloaded = false
			can_shoot = false
			ShootTimer.start()
	if event.is_action_pressed("ui_accept"):
		Destroy()
	if event.is_action_pressed("forward"):
		ThrusterSFX.play()
	if event.is_action_released("forward"):
		ThrusterSFX.stop()


func _physics_process(delta):
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - self.position).normalized()
	var direction_x = direction.tangent()
	
	# initial and final x-vector of basis
	var initial_transform_x = self.transform.x
	var final_transform_x = (mouse_position - self.global_position).normalized()
	# interpolate
	TurnSpeed.interpolate_method(self, '_set_rotation', initial_transform_x, 
	final_transform_x, TURN_SPEED, Tween.TRANS_LINEAR, Tween.EASE_OUT)
	TurnSpeed.start()
	look_at(mouse_position)
	
	if Input.get_action_strength("forward"):
		velocity = velocity.move_toward(direction * max_speed, ACCELERATION * delta)
		Thruster.set_visible(true)
	elif Input.get_action_strength("reverse"):
		velocity = velocity.move_toward(-direction * (max_speed * .6), ACCELERATION * delta)
		Thruster.set_visible(false)
	elif Input.get_action_strength("strafe_left"):
		velocity = velocity.move_toward(direction_x * (max_speed), ACCELERATION * delta) #Was (max_speed * .6)
		Thruster.set_visible(false)
	elif Input.get_action_strength("strafe_right"):
		velocity = velocity.move_toward(-direction_x * (max_speed), ACCELERATION * delta) #Was (max_speed * .6)
		Thruster.set_visible(false)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		Thruster.set_visible(false)
		
	var collision = move_and_collide(velocity)
	if collision:
		velocity = velocity.bounce(collision.normal)
		BumpSFX.play()

func _set_rotation(new_transform):
	# apply tweened x-vector of basis
	self.transform.x = new_transform
	# make x and y orthogonal and normalized
	self.transform = self.transform.orthonormalized()

func Shoot():
	var bullet = BULLET.instance()
#	bullet.target = "enemy"
	bullet.alliance = alliance
	get_parent().add_child(bullet)
	bullet.position = Gun.global_position
	bullet.velocity = Aim.global_position - bullet.position
	ShootSFX.play()

func Hit(bullet):
	if shields_active:
		Shield.look_at(bullet)
		Shield.set_frame(0)
		Shield.set_visible(true)
		Shield.play(alliance)
		shields -= 1
#		print(shields)
	else:
		hitpoints -= 1
		if hitpoints <= 0:
			Destroy()
	if shields == 0:
		shields_active = false
#		print(shields_active)
		ShieldArea.set_deferred("monitorable", false)

func Destroy():
	var explosion = EXPLOSION.instance()
	explosion.alliance = alliance
	get_parent().add_child(explosion)
	explosion.position = self.position
#	$Camera2D.queue_free()
#	get_parent().add_child(Camera2D)  # Maybe create DeathCamera scene and instance here
	self.queue_free()

func _on_Shield_animation_finished():
	Shield.set_visible(false)
