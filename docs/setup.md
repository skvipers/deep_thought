📦 Установка и использование Deep Thought
В руководстве приведены действия для подключения фреймворка и сборки минимально рабочей сцены.

1. Подключение плагина
Поместите папку addons/deep_thought в ваш проект.
Включите плагин в Project → Project Settings → Plugins.

2. Создание базовой сцены
Добавьте Node3D в качестве корневого узла.
Повесте world_preview.gd (из addons/deep_thought/previewers/world_preview.gd) на главную ноуд
Настройте экспортные пораметры:
Context - создайте новый GenerationContext
  a. Sedd - опционально
  b. Tile - пока опционально
  с. Presets - добавьте generator_preset.tres (из addons/deep_thought/data/presets/generator_preset.tres)
  d. Generators - создайте новый BasicTerrainGenerator и укажите ему пресет как в пункте c
  e. Global Parametrs - пока не используется
  f. Block Library - укажите block_library.tres (из addons/deep_thought/data/resources/block_library.tres)
ChunkScene - укажите путь к сцене chunk (из addons/deep_thought/scenes/chunk.tscn)
Origin Position - опционально, начальная позиция
ChunkSize - опционально, можно оставить стандартные параметры
ChunkRange - определяет количество чанков, 0, 0, 0 - 1 чанк; 1, 0, 1 9 чанков (3x3)
EditEnable - функция дебага для добавления и удаления блоков

Добавьте Camera3D как дочерняя нода главной Node3D
Выставьте позицию и угол камеры
При желании повесте на камеру fly_camera.gd (из addons/deep_thought/utils/fly_camera.gd)
Это позволит управлять камерой, поварачивать мышкой и изменять высоту
В управлении нужно добавить move_forward, move_backward, move_left, move_right, move_up, move_down
И назначить клавиши соответственно

Опционально, добавьте DirectionalLight3D
