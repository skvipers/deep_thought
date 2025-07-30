# 🦴 Система скелета паунов

## 🎯 **Улучшенная и модульная система**

Система скелета для паунов теперь использует единый подход с `UnifiedBoneData` и улучшенным `PawnSkeleton` с автоматическим следованием частей тела.

## 📁 **Структура файлов:**

### **Основные компоненты:**
- `UnifiedBoneData.gd` - единый класс для всех типов костей
- `PawnSkeletonData.gd` - данные скелета
- `PawnSkeleton.gd` - улучшенный контроллер с автоматическим следованием
- `PawnVisual.gd` - визуальный компонент с полным API
- `AttachmentData.gd` - привязки частей тела

### **Документация:**
- `automatic_following_guide.md` - руководство по автоматическому следованию

## 🦴 **UnifiedBoneData - единый класс для всех костей:**

### **Enum для типов костей:**
```gdscript
enum BoneType {
	SIMPLE,    # Простые кости (Node3D)
	SKELETON   # Скелетные кости (Skeleton3D)
}
```

### **Простые кости:**
```gdscript
var head_bone = UnifiedBoneData.new()
head_bone.setup_simple_bone("head", "head", "head/head_mesh")
# bone_type = BoneType.SIMPLE
```

### **Скелетные кости:**
```gdscript
var arm_bone = UnifiedBoneData.new()
arm_bone.setup_skeleton_bone("left_arm", "left_arm/ArmSkeleton", "left_arm/ArmSkeleton/left_arm_mesh", ["Shoulder", "Elbow"])
# bone_type = BoneType.SKELETON
```

## 🚀 **Быстрый старт:**

### **1. Создание скелета:**
```gdscript
var skeleton_data = PawnSkeletonData.new()

# Добавляем кости
var head_bone = UnifiedBoneData.new()
head_bone.setup_simple_bone("head", "head", "head/head_mesh")
skeleton_data.add_bone(head_bone)

var arm_bone = UnifiedBoneData.new()
arm_bone.setup_skeleton_bone("left_arm", "left_arm/ArmSkeleton", "left_arm/ArmSkeleton/left_arm_mesh")
skeleton_data.add_bone(arm_bone)
```

### **2. Использование улучшенного PawnSkeleton:**
```gdscript
# Автоматическое следование частей тела
pawn_skeleton.set_torso_rotation_with_following(Vector3(0, 0, deg_to_rad(20)))
pawn_skeleton.set_head_rotation_with_body_following(Vector3(0, 0, deg_to_rad(15)))

# Управление позами
pawn_skeleton.set_arm_pose("left", "raised")
pawn_skeleton.set_leg_pose("right", "walking")

# Сброс всех поз
pawn_skeleton.reset_all_poses()
```

### **3. Использование PawnVisual:**
```gdscript
# Полный API через PawnVisual
pawn_visual.set_torso_rotation_with_following(Vector3(0, 0, deg_to_rad(20)))
pawn_visual.set_arm_pose("left", "raised")
pawn_visual.configure_following_system(true, 0.3, 0.2, 0.4, 0.3)

# Анимации с fallback на позы
pawn_visual.play_animation("wave")
pawn_visual.stop_animation()
```

## ⚙️ **Настройки автоматического следования:**

```gdscript
# В PawnSkeleton можно настроить интенсивность следования
pawn_skeleton.enable_automatic_following = true
pawn_skeleton.head_follow_torso_intensity = 0.3
pawn_skeleton.torso_follow_head_intensity = 0.2
pawn_skeleton.arms_follow_torso_intensity = 0.4
pawn_skeleton.legs_follow_torso_intensity = 0.3

# Или через PawnVisual
pawn_visual.configure_following_system(true, 0.3, 0.2, 0.4, 0.3)
```

## 🎭 **Доступные позы:**

### **Руки:**
- `"idle"` - нейтральная поза
- `"raised"` - поднятая рука
- `"pointing"` - указывающая рука
- `"bent"` - согнутая рука

### **Ноги:**
- `"idle"` - нейтральная поза
- `"walking"` - поза ходьбы
- `"kicking"` - поза удара ногой

## 🔧 **Фабрики скелетов:**

Используйте `SkeletonFactory` для создания стандартных скелетов:

```gdscript
var humanoid_skeleton = SkeletonFactory.create_humanoid_skeleton()
var hybrid_skeleton = SkeletonFactory.create_hybrid_humanoid_skeleton()
var advanced_skeleton = SkeletonFactory.create_advanced_humanoid_skeleton()
```

## 📝 **Логирование:**

Система использует подробное логирование для отладки:

```gdscript
Logger.info("PAWN", "✅ Кость найдена и повернута")
Logger.debug("PAWN", "🔄 Применение автоматического следования")
Logger.warn("PAWN", "❌ Кость не найдена")
```

## 🎯 **Преимущества новой системы:**

1. **Автоматическое следование** - части тела следуют за основными костями
2. **Настраиваемая интенсивность** - можно настроить силу следования
3. **Модульность** - каждая часть тела независима
4. **Простота использования** - единый интерфейс для всех типов костей
5. **Подробное логирование** - легко отлаживать проблемы
6. **Полный API** - PawnVisual предоставляет все функции через единый интерфейс 
