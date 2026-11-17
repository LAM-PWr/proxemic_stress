/***
* Name: Hall with Adrenaline and Cortisol
* Author: Mikołaj Szurlej; Maciej Kamiński
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Hall_AC


global {
    
    file shape_file_roads <- file("Staszica_SHP_sciezki_01.shp");
    file shape_file_obstacles <- file("Staszica_SHP_krzaki_09.shp");
    geometry shape <- envelope(shape_file_roads);
    graph road_network;
    float step <- 0.005 #mn;
    int number_of_flags <- 0;

	float hall_multiplier <- 4.0;

	float intymny   <-  0.45* hall_multiplier;
	float osobniczy <-  1.2 * hall_multiplier;
	float spoleczny <-  3.6 * hall_multiplier;
	float publiczny <- 10.0 * hall_multiplier;
	
	
	int phantom_nb <- 1;
	int bot_nb <- 10;
    
    init {
    	create from: shape_file_obstacles species: obstacle  ;        
        create road from: shape_file_roads ;
        create bot number: bot_nb {
        	speed <- 4 #km/#h + gauss(0,0.3);
			location <- any_location_in( one_of(road) );
			target <- location;
			shape <- triangle(5);
			
        }
        create phantom number: phantom_nb {
        	speed <- 4 #km/#h ;
			location <- any_location_in(one_of(road));
			target <- location;
			shape <- triangle(10);
			
		}
		
		road_network <- as_edge_graph(road);
    }
}

species road {
    rgb color <- #black ;
    aspect default {
    	draw shape color: color ;
	}
}

species obstacle {

	aspect default {
		draw shape color: #green at: location ;
	}
	
}

species bot skills: [moving] {
	point target;
	
	reflex normal_move {
		if ((target distance_to location)<1#m) {
			target <- any_location_in(one_of(road));
		}
		else {
			do goto target: target on: road_network;
		}
	}
	
	aspect default {
		draw shape rotate: heading + 90 color: #brown;
	}
}

species phantom skills: [moving] {


   point target;
 
   float vigilance <- 0.5;           // Uważność — potrzeba śledzenia otoczenia
   float adrenaline <- 0.5;          // Adrenalina — szybka reakcja
   float cortisol <- 0.5;            // Kortyzol — przewlekły stres

   float adrenaline_cooldown <- 0.99; // Tempo wygasania adrenaliny
   float cortisol_cooldown <- 0.999;  // Tempo wygasania kortyzolu
   
   list<int> where_are_they <- [];
   list<int> where_were_they <- [];  // Poprzedni stan percepcji




   reflex update_psychophysiology {
      where_are_they <- phantom collect distance_number(each.location);
      
      cortisol <- cortisol * cortisol_cooldown;
      cortisol <- cortisol + 0.002*adrenaline; // ((cortisol + 1.0)*(cortisol + 1.0)); // mniejszy wzrost gdy dużo stresu

      vigilance <- required_vigilance();

      adrenaline <- adrenaline * adrenaline_cooldown;
      adrenaline <- adrenaline + vigilance; // (adrenaline + 1.0);

      where_were_they <- where_are_they;
   }

   geometry publiczny_perception_geometry  update: circle(publiczny, location)  masked_by obstacle;
   geometry spoleczny_perception_geometry  update: circle(spoleczny, location)  masked_by obstacle;
   geometry osobniczy_perception_geometry  update: circle(osobniczy, location)  masked_by obstacle;
   geometry intymny_perception_geometry    update: circle(intymny, location)    masked_by obstacle;
   int distance_number(geometry loc) {
   	
      if (intymny_perception_geometry covers loc)     { return 4; }
      if (osobniczy_perception_geometry covers loc)   { return 3; }
      if (spoleczny_perception_geometry covers loc)   { return 2; }
      if (publiczny_perception_geometry covers loc)   { return 1; }
      return 0;
   }

   float required_vigilance {
      if (length(where_were_they) = 0) {
         return 0.0;
      }
      float total <- 0.0;
      loop i from: 0 to: (length(where_are_they) - 1) {
         if (where_were_they[i] < where_are_they[i]) {
            int diff <- where_are_they[i] - where_were_they[i];
            total <- total + (diff * diff - 0.99); 
         }
      }
      return total;
   }
	
	reflex normal_move {
		if ((target distance_to location)<1) {
			target <- any_location_in(one_of(road));
		}
		else {
			do goto target: target on: road_network;
		}
	}
	
	aspect hall {
    	draw publiczny_perception_geometry color: blend(#brown, #blue, 0.3) ;
	}

	aspect hall2 {
    	draw spoleczny_perception_geometry color: blend(#brown, #blue, 0.8) ;
	}
	aspect default {
		draw shape rotate: heading + 90 color: #blue;
	}
}



experiment Hall type: gui {
	parameter "liczba phantomów" var: phantom_nb;
	parameter "liczba botów" var: bot_nb;
	parameter "dystans intymny" var: intymny;
	parameter "dystans osobniczy" var: osobniczy;
	parameter "dystans spoleczny" var: spoleczny;
	parameter "dystans publiczny" var: publiczny;
    output {
        display city_display type:opengl {
   	        species road  refresh: false;
   	        species obstacle refresh: false;
   	        species phantom aspect: hall;
   	        species phantom aspect: hall2;
   	        species phantom aspect: default;
   	        species bot;

   	    }
   	    display chart_1 type: 2d refresh: every(1#cycle) {
			chart "Data" memorize: false y_range:{-0.1,15} type: series {
				data "adrenaline" value: phantom[0].adrenaline color:#blue;
				data "kortyzol" value: phantom[0].cortisol color: #purple;
				data "vigilance" value: phantom[0].vigilance color: #black;
				//data "DIST" value: people[0].dist color: #red;
				
				}
			
			chart "Data2" memorize: false y_range:{-0.1,15} type: series {
				data "adrenaline" value: phantom[0].adrenaline color:#blue;
				data "kortyzol" value: phantom[0].cortisol color: #purple;
				data "vigilance" value: phantom[0].vigilance color: #black;
				//data "DIST" value: people[0].dist color: #red;	
			}
			
		}
			
    }
}
