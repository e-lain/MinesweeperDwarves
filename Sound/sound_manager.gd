extends Node

@export var uncover_tile_sounds: Array[AudioStream]
@export var page_turn_sounds: Array[AudioStream]
@export var building_placement_sounds: Array[AudioStream]
@export var explosions: Array[AudioStream]
@export var negative: Array[AudioStream]
@export var positive: Array[AudioStream]

@export var flag_sounds: Array[AudioStream]

@export var crane_sounds: Array[AudioStream]
@export var armor_sounds: Array[AudioStream]
@export var dowse_sounds: Array[AudioStream]

@export var collection_sounds: Array[AudioStream]


@onready var sfx_player = $SFXPlayer
@onready var sfx_player2 = $SFXPlayer2

func play_sound(stream: AudioStream):
	var player = sfx_player2 if sfx_player.playing else sfx_player
	player.stop()
	player.stream = stream
	player.play(0)

func play_uncover_tile_sound():
	play_sound(uncover_tile_sounds.pick_random())

func play_page_turn_sound():
	play_sound(page_turn_sounds.pick_random())

func play_flag_sound():
	play_sound(flag_sounds.pick_random())

func play_building_placement_sound():
	play_sound(building_placement_sounds.pick_random())
	
func play_explosion_sound():
	play_sound(explosions.pick_random())

func play_negative():
	play_sound(negative.pick_random())
	
func play_positive():
	play_sound(positive.pick_random())

func play_armor():
	play_sound(armor_sounds.pick_random())

func play_crane():
	play_sound(crane_sounds.pick_random())


func play_dowse():
	play_sound(dowse_sounds.pick_random())

func play_collection():
	play_sound(collection_sounds.pick_random())
