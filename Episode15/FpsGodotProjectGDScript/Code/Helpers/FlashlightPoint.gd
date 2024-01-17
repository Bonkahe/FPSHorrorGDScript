extends Marker3D

class_name FlashlightPoint

enum Priority {none, low, medium, high};
@export var priority : Priority = Priority.none;
var HasBeenTargeted : bool;
