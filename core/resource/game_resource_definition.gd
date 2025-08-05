# Файл: addons/deep_thought/core/resource/game_resource_definition.gd
class_name GameResourceDefinition
extends Resource

## Уникальный ID ресурса (например, "log", "gold", "research_tier1")
@export var id: String

## Отображаемое имя для UI
@export var display_name: String

## Описание для UI
@export var description: String

## Иконка для UI
@export var icon: Texture2D

## Теги для категоризации (например, "wood", "metal", "currency", "research")
@export var tags: Array[String]
