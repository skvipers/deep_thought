#
# TODO: Требуется рефакторинг для повышения гибкости.
#
# Текущая реализация имеет несколько проблем:
# 1. Жестко закодированные пути в `preload()`: Зависимости (UnifiedBoneData, AttachmentData, Logger)
#    загружаются с использованием полных путей `res://`. Это делает систему хрупкой
#    к изменениям в структуре папок. Рекомендуется использовать `class_name` и 
#    позволить Godot управлять зависимостями, либо передавать классы как параметры.
# 2. Жестко закодированные пути к нодам и мешам: В методах, создающих скелеты (например,
#    create_humanoid_skeleton), пути к нодам `Skeleton3D` и мешам заданы как строки.
#    Это предполагает очень специфическую структуру сцены и ломается при ее изменении.
# 3. Жестко закодированная конфигурация скелетов: Вся конфигурация для стандартных
#    скелетов находится прямо в коде. Это делает невозможным простое добавление
#    новых типов скелетов или изменение существующих без редактирования этого файла.
#
# Рекомендации по улучшению:
# - Создать кастомный ресурс, например `SkeletonDataResource.gd`, который будет
#   хранить всю информацию о скелете (список костей, пути к мешам, точки крепления).
# - Для каждого типа скелета создать свой `.tres` файл на основе `SkeletonDataResource`.
# - Изменить фабрику, чтобы она имела один общий метод, например
#   `create_skeleton(skeleton_resource: SkeletonDataResource)`, который будет строить
#   скелет на основе данных из переданного ресурса.
#
class_name SkeletonFactory

static func create_humanoid_skeleton() -> PawnSkeletonData:
	"""Creates standard humanoid skeleton"""
	Logger.info("PAWN", "Creating humanoid skeleton")
	var skeleton_data = PawnSkeletonData.new()
	
	# Main bones
	var spine_bone = UnifiedBoneData.new()
	spine_bone.setup_simple_bone("spine", "spine", "spine/spine_mesh")
	spine_bone.position = Vector3(0, 1.0, 0)
	skeleton_data.add_bone(spine_bone)
	
	var head_bone = UnifiedBoneData.new()
	head_bone.setup_simple_bone("head", "head", "head/head_mesh")
	head_bone.position = Vector3(0, 1.7, 0)
	skeleton_data.add_bone(head_bone)
	
	var left_arm_bone = UnifiedBoneData.new()
	left_arm_bone.setup_skeleton_bone("left_arm", "left_arm/ArmSkeleton", "left_arm/ArmSkeleton/left_arm_mesh", ["Shoulder", "Elbow"])
	left_arm_bone.position = Vector3(-0.3, 1.4, 0)
	skeleton_data.add_bone(left_arm_bone)
	
	var right_arm_bone = UnifiedBoneData.new()
	right_arm_bone.setup_skeleton_bone("right_arm", "right_arm/ArmSkeleton", "right_arm/ArmSkeleton/right_arm_mesh", ["Shoulder", "Elbow"])
	right_arm_bone.position = Vector3(0.3, 1.4, 0)
	skeleton_data.add_bone(right_arm_bone)
	
	var left_leg_bone = UnifiedBoneData.new()
	left_leg_bone.setup_skeleton_bone("left_leg", "left_leg/LegSkeleton", "left_leg/LegSkeleton/left_leg_mesh", ["Hip", "Knee"])
	left_leg_bone.position = Vector3(-0.1, 0.5, 0)
	skeleton_data.add_bone(left_leg_bone)
	
	var right_leg_bone = UnifiedBoneData.new()
	right_leg_bone.setup_skeleton_bone("right_leg", "right_leg/LegSkeleton", "right_leg/LegSkeleton/right_leg_mesh", ["Hip", "Knee"])
	right_leg_bone.position = Vector3(0.1, 0.5, 0)
	skeleton_data.add_bone(right_leg_bone)
	
	# Body part attachments
	skeleton_data.add_attachment(AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("left_arm", "left_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("right_arm", "right_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("left_leg", "left_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("right_leg", "right_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("torso", "spine", Vector3.ZERO, Vector3.ZERO))
	
	Logger.info("PAWN", "Humanoid skeleton created successfully")
	return skeleton_data

static func create_hybrid_humanoid_skeleton() -> PawnSkeletonData:
	"""Creates hybrid humanoid skeleton (simple + Skeleton3D)"""
	Logger.info("PAWN", "Creating hybrid humanoid skeleton")
	var skeleton_data = PawnSkeletonData.new()
	
	# Simple bones (head, torso)
	var head = UnifiedBoneData.new()
	head.setup_simple_bone("head", "head", "head/head_mesh")
	head.position = Vector3(0, 1.7, 0)
	skeleton_data.add_bone(head)
	
	var spine = UnifiedBoneData.new()
	spine.setup_simple_bone("spine", "spine", "spine/spine_mesh")
	spine.position = Vector3(0, 1.0, 0)
	skeleton_data.add_bone(spine)
	
	# Skeleton3D bones (arms, legs)
	var left_arm = UnifiedBoneData.new()
	left_arm.setup_skeleton_bone("left_arm", "left_arm/ArmSkeleton", "left_arm/ArmSkeleton/left_arm_mesh", ["Shoulder", "Elbow"])
	left_arm.position = Vector3(-0.3, 1.4, 0)
	skeleton_data.add_bone(left_arm)
	
	var right_arm = UnifiedBoneData.new()
	right_arm.setup_skeleton_bone("right_arm", "right_arm/ArmSkeleton", "right_arm/ArmSkeleton/right_arm_mesh", ["Shoulder", "Elbow"])
	right_arm.position = Vector3(0.3, 1.4, 0)
	skeleton_data.add_bone(right_arm)
	
	var left_leg = UnifiedBoneData.new()
	left_leg.setup_skeleton_bone("left_leg", "left_leg/LegSkeleton", "left_leg/LegSkeleton/left_leg_mesh", ["Hip", "Knee"])
	left_leg.position = Vector3(-0.1, 0.5, 0)
	skeleton_data.add_bone(left_leg)
	
	var right_leg = UnifiedBoneData.new()
	right_leg.setup_skeleton_bone("right_leg", "right_leg/LegSkeleton", "right_leg/LegSkeleton/right_leg_mesh", ["Hip", "Knee"])
	right_leg.position = Vector3(0.1, 0.5, 0)
	skeleton_data.add_bone(right_leg)
	
	# Body part attachments
	skeleton_data.add_attachment(AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("left_arm", "left_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("right_arm", "right_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("left_leg", "left_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("right_leg", "right_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("torso", "spine", Vector3.ZERO, Vector3.ZERO))
	
	Logger.info("PAWN", "Hybrid humanoid skeleton created successfully")
	return skeleton_data

static func create_advanced_humanoid_skeleton() -> PawnSkeletonData:
	"""Создает продвинутый человеческий скелет с детальными костями"""
	var skeleton_data = PawnSkeletonData.new()
	
	# Позвоночник с несколькими суставами
	var spine = UnifiedBoneData.new()
	spine.setup_skeleton_bone("spine", "spine/SpineSkeleton", "spine/SpineSkeleton/spine_mesh", ["Neck", "Chest", "Waist", "Hip"])
	spine.position = Vector3(0, 1.0, 0)
	skeleton_data.add_bone(spine)
	
	# Голова
	var head = UnifiedBoneData.new()
	head.setup_simple_bone("head", "head", "head/head_mesh")
	head.position = Vector3(0, 1.7, 0)
	skeleton_data.add_bone(head)
	
	# Руки с локтями
	var left_arm = UnifiedBoneData.new()
	left_arm.setup_skeleton_bone("left_arm", "left_arm/ArmSkeleton", "left_arm/ArmSkeleton/left_arm_mesh", ["Shoulder", "Elbow", "Wrist"])
	left_arm.position = Vector3(-0.3, 1.4, 0)
	skeleton_data.add_bone(left_arm)
	
	var right_arm = UnifiedBoneData.new()
	right_arm.setup_skeleton_bone("right_arm", "right_arm/ArmSkeleton", "right_arm/ArmSkeleton/right_arm_mesh", ["Shoulder", "Elbow", "Wrist"])
	right_arm.position = Vector3(0.3, 1.4, 0)
	skeleton_data.add_bone(right_arm)
	
	# Ноги с коленями
	var left_leg = UnifiedBoneData.new()
	left_leg.setup_skeleton_bone("left_leg", "left_leg/LegSkeleton", "left_leg/LegSkeleton/left_leg_mesh", ["Hip", "Knee", "Ankle"])
	left_leg.position = Vector3(-0.1, 0.5, 0)
	skeleton_data.add_bone(left_leg)
	
	var right_leg = UnifiedBoneData.new()
	right_leg.setup_skeleton_bone("right_leg", "right_leg/LegSkeleton", "right_leg/LegSkeleton/right_leg_mesh", ["Hip", "Knee", "Ankle"])
	right_leg.position = Vector3(0.1, 0.5, 0)
	skeleton_data.add_bone(right_leg)
	
	# Привязки для частей тела
	skeleton_data.add_attachment(AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("left_arm", "left_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("right_arm", "right_arm", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("left_leg", "left_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("right_leg", "right_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("torso", "spine", Vector3.ZERO, Vector3.ZERO))
	
	return skeleton_data

static func create_flexible_creature_skeleton() -> PawnSkeletonData:
	"""Создает скелет гибкого существа (змея, червь и т.д.)"""
	var skeleton_data = PawnSkeletonData.new()
	
	# Гибкий позвоночник с множеством сегментов
	var spine = UnifiedBoneData.new()
	spine.setup_skeleton_bone("spine", "spine/SpineSkeleton", "spine/SpineSkeleton/spine_mesh", ["Segment1", "Segment2", "Segment3", "Segment4", "Segment5", "Segment6", "Segment7", "Segment8"])
	spine.position = Vector3(0, 0.5, 0)
	skeleton_data.add_bone(spine)
	
	# Голова
	var head = UnifiedBoneData.new()
	head.setup_simple_bone("head", "head", "head/head_mesh")
	head.position = Vector3(0, 1.3, 0)
	skeleton_data.add_bone(head)
	
	# Привязки
	skeleton_data.add_attachment(AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("body", "spine", Vector3.ZERO, Vector3.ZERO))
	
	return skeleton_data

static func create_quadruped_skeleton() -> PawnSkeletonData:
	"""Создает скелет четвероногого существа"""
	var skeleton_data = PawnSkeletonData.new()
	
	# Основные кости
	var spine = UnifiedBoneData.new()
	spine.setup_simple_bone("spine", "spine", "spine/spine_mesh")
	spine.position = Vector3(0, 0.8, 0)
	skeleton_data.add_bone(spine)
	
	var head = UnifiedBoneData.new()
	head.setup_simple_bone("head", "head", "head/head_mesh")
	head.position = Vector3(0, 1.0, 0.3)
	skeleton_data.add_bone(head)
	
	var tail = UnifiedBoneData.new()
	tail.setup_simple_bone("tail", "tail", "tail/tail_mesh")
	tail.position = Vector3(0, 0.6, -0.5)
	skeleton_data.add_bone(tail)
	
	var front_left_leg = UnifiedBoneData.new()
	front_left_leg.setup_skeleton_bone("front_left_leg", "front_left_leg/LegSkeleton", "front_left_leg/LegSkeleton/front_left_leg_mesh", ["Hip", "Knee"])
	front_left_leg.position = Vector3(-0.2, 0.4, 0.2)
	skeleton_data.add_bone(front_left_leg)
	
	var front_right_leg = UnifiedBoneData.new()
	front_right_leg.setup_skeleton_bone("front_right_leg", "front_right_leg/LegSkeleton", "front_right_leg/LegSkeleton/front_right_leg_mesh", ["Hip", "Knee"])
	front_right_leg.position = Vector3(0.2, 0.4, 0.2)
	skeleton_data.add_bone(front_right_leg)
	
	var back_left_leg = UnifiedBoneData.new()
	back_left_leg.setup_skeleton_bone("back_left_leg", "back_left_leg/LegSkeleton", "back_left_leg/LegSkeleton/back_left_leg_mesh", ["Hip", "Knee"])
	back_left_leg.position = Vector3(-0.2, 0.4, -0.2)
	skeleton_data.add_bone(back_left_leg)
	
	var back_right_leg = UnifiedBoneData.new()
	back_right_leg.setup_skeleton_bone("back_right_leg", "back_right_leg/LegSkeleton", "back_right_leg/LegSkeleton/back_right_leg_mesh", ["Hip", "Knee"])
	back_right_leg.position = Vector3(0.2, 0.4, -0.2)
	skeleton_data.add_bone(back_right_leg)
	
	# Привязки для частей тела
	skeleton_data.add_attachment(AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("tail", "tail", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("front_left_leg", "front_left_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("front_right_leg", "front_right_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("back_left_leg", "back_left_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("back_right_leg", "back_right_leg", Vector3.ZERO, Vector3.ZERO))
	skeleton_data.add_attachment(AttachmentData.new("torso", "spine", Vector3.ZERO, Vector3.ZERO))
	
	return skeleton_data

static func create_custom_skeleton(bones: Array[UnifiedBoneData], attachments: Array[AttachmentData]) -> PawnSkeletonData:
	"""Создает кастомный скелет"""
	var skeleton_data = PawnSkeletonData.new()
	
	for bone in bones:
		skeleton_data.add_bone(bone)
	
	for attachment in attachments:
		skeleton_data.add_attachment(attachment)
	
	return skeleton_data

static func create_skeleton_from_resource(skeleton_resource: PawnSkeletonData) -> PawnSkeletonData:
	"""Создает копию скелета из ресурса"""
	var new_skeleton = PawnSkeletonData.new()
	
	for bone in skeleton_resource.bones:
		new_skeleton.add_bone(bone.duplicate())
	
	for attachment in skeleton_resource.attachments:
		new_skeleton.add_attachment(attachment.duplicate())
	
	return new_skeleton 
