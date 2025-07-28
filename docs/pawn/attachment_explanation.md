# 🔗 AttachmentData - объяснение полей

## 🎯 **Назначение AttachmentData:**

`AttachmentData` используется для создания **точек привязки** частей тела к костям скелета. Это позволяет:
- Прикреплять протезы к определенным костям
- Размещать части тела в правильных позициях
- Управлять трансформацией частей тела относительно костей

## 📝 **Поля AttachmentData:**

### **`part_name` - имя части тела:**
- **Что это:** Логическое имя части тела (например, "head", "left_arm", "torso")
- **Для чего:** Используется для поиска привязки в системе
- **Примеры:** `"head"`, `"left_arm"`, `"right_leg"`, `"torso"`, `"tail"`

### **`bone_name` - имя кости для привязки:**
- **Что это:** Имя кости из `UnifiedBoneData`, к которой привязывается часть тела
- **Для чего:** Определяет, к какой кости будет прикреплена часть тела
- **Примеры:** `"head"`, `"left_arm"`, `"spine"`, `"tail"`

### **`position` - позиция относительно кости:**
- **Что это:** Смещение от центра кости
- **Для чего:** Точное позиционирование части тела
- **Примеры:** `Vector3(0, 0, 0)` - по центру, `Vector3(0, 10, 0)` - выше на 10 единиц

### **`rotation` - поворот относительно кости:**
- **Что это:** Поворот части тела относительно кости
- **Для чего:** Правильная ориентация части тела
- **Примеры:** `Vector3(0, 0, 0)` - без поворота, `Vector3(0, 90, 0)` - поворот на 90° по Y

### **`scale` - масштаб части тела:**
- **Что это:** Размер части тела относительно кости
- **Для чего:** Изменение размера протезов или частей тела
- **Примеры:** `Vector3(1, 1, 1)` - нормальный размер, `Vector3(1.5, 1.5, 1.5)` - увеличение в 1.5 раза

## 🔗 **Как это работает:**

### **1. Создание привязки:**
```gdscript
var head_attachment = AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO)
# part_name = "head" - логическое имя части тела
# bone_name = "head" - имя кости для привязки
```

### **2. Использование в системе:**
```gdscript
# В PawnSkeleton._create_attachment():
var attachment = Node3D.new()
attachment.name = "Attachment_" + attachment_data.part_name  # "Attachment_head"
attachment.position = attachment_data.position
attachment.rotation = attachment_data.rotation

# Привязываем к кости:
var parent_bone = bones.get(attachment_data.bone_name)  # Ищем кость "head"
if parent_bone:
    parent_bone.add_child(attachment)  # Привязываем к кости
```

### **3. Поиск привязки:**
```gdscript
# В PawnSkeleton.get_attachment():
var attachment = bone_attachments.get(part_name)  # Ищем по "head"
```

## 📋 **Примеры использования:**

### **Человеческий скелет:**
```gdscript
# Голова привязана к кости головы
AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO)

# Левая рука привязана к кости левой руки
AttachmentData.new("left_arm", "left_arm", Vector3.ZERO, Vector3.ZERO)

# Туловище привязано к позвоночнику
AttachmentData.new("torso", "spine", Vector3.ZERO, Vector3.ZERO)
```

### **Животное (собака):**
```gdscript
# Хвост привязан к кости хвоста
AttachmentData.new("tail", "tail", Vector3.ZERO, Vector3.ZERO)

# Передние лапы привязаны к соответствующим костям
AttachmentData.new("front_left_leg", "front_left_leg", Vector3.ZERO, Vector3.ZERO)
AttachmentData.new("front_right_leg", "front_right_leg", Vector3.ZERO, Vector3.ZERO)
```

### **Смещенные привязки:**
```gdscript
# Протез руки со смещением
AttachmentData.new("prosthetic_arm", "left_arm", Vector3(5, 0, 0), Vector3(0, 45, 0))

# Шлем на голове
AttachmentData.new("helmet", "head", Vector3(0, 10, 0), Vector3.ZERO)
```

## 🎯 **Логика именования:**

### **`part_name` - что указывать:**
- ✅ **Логическое имя части тела:** `"head"`, `"left_arm"`, `"torso"`
- ✅ **Описательное имя:** `"prosthetic_arm"`, `"helmet"`, `"backpack"`
- ❌ **Не указывать:** технические имена узлов, случайные строки

### **`bone_name` - что указывать:**
- ✅ **Имя кости из UnifiedBoneData:** `"head"`, `"left_arm"`, `"spine"`
- ✅ **Должно существовать в bones массиве**
- ❌ **Не указывать:** несуществующие кости, случайные имена

## 🔧 **Практические советы:**

### **1. Согласованность имен:**
```gdscript
# Хорошо - имена совпадают
AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO)

# Тоже хорошо - разные имена, но логично
AttachmentData.new("helmet", "head", Vector3.ZERO, Vector3.ZERO)
AttachmentData.new("torso", "spine", Vector3.ZERO, Vector3.ZERO)
```

### **2. Позиционирование:**
```gdscript
# По центру кости
AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO)

# Со смещением
AttachmentData.new("prosthetic", "left_arm", Vector3(5, 0, 0), Vector3.ZERO)

# С поворотом
AttachmentData.new("weapon", "right_arm", Vector3.ZERO, Vector3(0, 90, 0))
```

### **3. Масштабирование:**
```gdscript
# Нормальный размер
var attachment = AttachmentData.new("head", "head", Vector3.ZERO, Vector3.ZERO)
attachment.scale = Vector3(1, 1, 1)

# Увеличенный протез
var prosthetic = AttachmentData.new("prosthetic_arm", "left_arm", Vector3.ZERO, Vector3.ZERO)
prosthetic.scale = Vector3(1.2, 1.2, 1.2)
```

## 🎉 **Итог:**

**`part_name`** - логическое имя части тела для поиска в системе
**`bone_name`** - имя кости из UnifiedBoneData для физической привязки

**Система позволяет гибко привязывать любые части тела к любым костям!** 🚀 