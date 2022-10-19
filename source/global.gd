extends Node

var character := 'repenter';

var theme_values := [['break-N-enter', Color(0, 1, 0)], 
					 ['Fire and brimstone', Color(.8, .6, .1)], 
					 ['#FF69B4', Color(1, 0, 0)], 
					 ['razzle-dazzle', Color(1, 0.4, 0.7)]];

var theme_id := 0;

var font_values := [['Bohemian Typewriter', 'res://fonts/Bohemian Typewriter.ttf'], 
					['Berylium Regular', 'res://fonts/Berylium Regular.ttf'], 
					['Vinque Regular', 'res://fonts/Vinque Regular.ttf'], 
					['Anke Print', 'res://fonts/Anke Print.TTF']];

var font_id := 0;


func save():
	var save_dict = {
		"name": "global",
		"theme_id": theme_id,
		"font_id": font_id};
	return save_dict;
