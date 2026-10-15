extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = load("res://main_ship.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game.director.stop()
	assert(not InputMap.has_action("aim_mode"), "Right-click aiming is still bound")
	var manager = game.player.weapons_manager
	assert(manager.viewmodels.size() == 4)
	for model in manager.viewmodels:
		assert(model.find_children("*", "MeshInstance3D", true, false).size() > 0, "Gun model missing")
	var ammo_before: int = manager.current_weapon.current_mag
	assert(manager.current_weapon.try_fire(true))
	assert(manager.current_weapon.current_mag < ammo_before, "Weapon firing broke")
	var center: Vector3 = game.sector.room_center(2, 3)
	game.player.global_position = center + Vector3(0, 0.2, 0)
	game.director._spawn_at(center + Vector3(0, 0.2, -4.8), true)
	var enemy = game.get_node("Enemies").get_child(0)
	assert(enemy.get_node("character_undead").visible, "Original zombie model missing")
	assert(not enemy.has_node("character_undead/TexturedZombie"), "Replacement zombie is still active")
	assert(manager.current_weapon.muzzle_flash_position == manager.muzzle_markers[0], "Flash is detached from the visible muzzle")
	game.player.camera_pivot.rotation = Vector3.ZERO
	game.player.camera_holder.rotation = Vector3.ZERO
	for i in 3:
		await physics_frame
	var enemy_health_before: float = enemy.current_health
	manager.current_weapon.can_fire = true
	manager.current_weapon.fire_weapon()
	assert(enemy.current_health < enemy_health_before, "Shot from visible muzzle missed the target")
	enemy._change_state("attack")
	var health_before: float = game.player.current_health
	enemy.global_position = game.player.global_position + Vector3(0, 0, -1.0)
	enemy.player = game.player
	enemy._deal_damage()
	assert(game.player.current_health < health_before, "Zombie attack damage broke")
	enemy.get_damage(1000.0, Vector3.FORWARD)
	assert(get_nodes_in_group("blood_stain").size() == 1, "Blood stain missing")
	print("PASS: replacement guns, fire, original zombie, attack damage, blood")
	game.queue_free()
	await process_frame
	quit()
