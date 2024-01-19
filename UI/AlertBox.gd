extends PanelContainer
class_name AlertBox

signal delayed_close_complete

@onready var header: RichTextLabel = $RichTextLabel
@onready var content: RichTextLabel = $RichTextLabel2
@onready var buttons = $Buttons
@onready var proceed_button = $Buttons/ProceedButton
@onready var cancel_button = $Buttons/CancelButton

@export var close_delay_time_seconds: float = 2.0

var current_proceed_callback
var current_cancel_callback

enum ButtonStyle
{
	None,
	Proceed,
	Restart,
}

# TODO: animate this
func show_content(header: String, content: String, size: Vector2, button_style: ButtonStyle, proceed_callback = null, cancel_callback = null):
	self.custom_minimum_size = size
	self.header.text = header
	self.content.text = content
	self.buttons.visible = button_style != ButtonStyle.None
	current_proceed_callback = proceed_callback
	current_cancel_callback = cancel_callback
	if button_style == ButtonStyle.Proceed:
		proceed_button.text = "Proceed"
		cancel_button.text = "Cancel"
		proceed_button.visible = true
		cancel_button.visible = true
	elif button_style == ButtonStyle.Restart:
		proceed_button.text = "Restart"
		proceed_button.visible = true
		cancel_button.visible = false
	elif button_style == ButtonStyle.None:
		var timer = get_tree().create_timer(close_delay_time_seconds)
		timer.timeout.connect(on_close_delay_complete)
	
	visible = true

func on_close_delay_complete():
	visible = false
	if current_proceed_callback != null:
		current_proceed_callback.call()


func _on_proceed_button_pressed():
	if current_proceed_callback != null:
		current_proceed_callback.call()


func _on_cancel_button_pressed():
	if current_cancel_callback != null:
		current_cancel_callback.call()
