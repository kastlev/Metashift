extends CanvasLayer

@onready var sfx_hover: AudioStreamPlayer2D = %SfxHover
@onready var sfx_confirm: AudioStreamPlayer2D = %SfxConfirm
@onready var sfx_back: AudioStreamPlayer2D = %SfxBack
@onready var sfx_menu_pause_entered: AudioStreamPlayer2D = %SfxMenuPauseEntered

@onready var btn_resume: Button = %Resume
@onready var btn_retry: Button = %Retry
@onready var btn_opcions: Button = %Opcions
@onready var btn_quit: Button = %Quit
@onready var global_canvas_modulate = %CanvasModulate
@onready var fade: ColorRect = %Fade
@onready var reticle: Sprite2D = %Reticle
@onready var back_buffer_copy: BackBufferCopy = %BackBufferCopy
@onready var blur_h: ColorRect = %BlurH
@onready var blur_v: ColorRect = %BlurV
@onready var frozen_blur: TextureRect = %FrozenBlur

var _buttons: Array[Button] = []
var _using_mouse: bool = false

func _ready() -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	_buttons = [btn_resume, btn_retry, btn_opcions, btn_quit]
	_setup_focus_wrap()
	for btn in _buttons:
		btn.focus_mode = Control.FOCUS_ALL
		btn.mouse_entered.connect(_on_button_mouse_entered.bind(btn))
		btn.focus_entered.connect(_on_button_focus_entered)
		btn.pressed.connect(_on_button_pressed_sfx)
	btn_resume.pressed.connect(func(): print("continue"))
	btn_retry.pressed.connect(func(): print("reset"))
	btn_quit.pressed.connect(func(): print("exit"))
	btn_resume.pressed.connect(_hide)
	btn_retry.pressed.connect(_on_reset_pressed)
	btn_quit.pressed.connect(_on_exit_pressed)

func _setup_focus_wrap() -> void:
	var count := _buttons.size()
	for i in count:
		var current := _buttons[i]
		var next := _buttons[(i + 1) % count]
		var prev := _buttons[(i - 1 + count) % count]
		current.focus_neighbor_bottom = current.get_path_to(next)
		current.focus_neighbor_top = current.get_path_to(prev)

func _on_button_focus_entered() -> void:
	sfx_hover.play()

func _on_button_pressed_sfx() -> void:
	sfx_confirm.play()

func _input(event: InputEvent) -> void:
	if not visible:
		if event.is_action_pressed("ui_cancel"):
			_show()
			sfx_menu_pause_entered.play()
		return

	if event.is_action_pressed("ui_cancel"):
		_hide()
		get_viewport().set_input_as_handled()

	if event is InputEventMouseMotion:
		if event.relative.length() > 1.0 and not _using_mouse:
			_set_mouse_mode(true)
	elif event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event.is_pressed() and _using_mouse:
			_set_mouse_mode(false)

func _set_mouse_mode(using_mouse: bool) -> void:
	_using_mouse = using_mouse
	var filter := Control.MOUSE_FILTER_STOP if using_mouse else Control.MOUSE_FILTER_IGNORE
	for btn in _buttons:
		btn.mouse_filter = filter

	if using_mouse:
		var focused := get_viewport().gui_get_focus_owner()
		if focused:
			focused.release_focus()
	else:
		_restore_keyboard_focus()

func _on_button_mouse_entered(btn: Button) -> void:
	if _using_mouse:
		btn.grab_focus()

func _restore_keyboard_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not _buttons.has(focused):
		btn_resume.grab_focus()

func _process(_delta: float) -> void:
	if visible:
		reticle.global_position = get_viewport().get_mouse_position()

func _show() -> void:
	get_tree().paused = true
	show()
	_set_mouse_mode(false)
	btn_resume.grab_focus()
	btn_resume.pivot_offset = btn_resume.size / 2

	blur_h.visible = true
	blur_v.visible = true
	frozen_blur.visible = false
	reticle.visible = false

	await get_tree().process_frame
	await get_tree().process_frame

	_freeze_blur()

	reticle.visible = true
	_freeze_blur()

func _freeze_blur() -> void:
	var img := get_viewport().get_texture().get_image()
	var frozen_texture := ImageTexture.create_from_image(img)

	frozen_blur.texture = frozen_texture
	frozen_blur.visible = true

	blur_h.visible = false
	blur_v.visible = false

func _hide() -> void:
	get_tree().paused = false
	hide()
	frozen_blur.visible = false

func _on_reset_pressed() -> void:
	fade.visible = true
	var tween := create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 0.3)
	await tween.finished
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
