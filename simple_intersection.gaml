/**
* Name: simpleintersction
* Author: ZHONG Junjie
*/

model simpleintersction

global {   
	file shape_file_roads  <- file("../includes/intersection/easy/simple_network.shp") ;
	file shape_file_nodes  <- file("../includes/intersection/easy/simple_nodes.shp");//simple_nodes2
	geometry shape <- envelope(shape_file_roads);

	int nb_people <-0; //10
	int nb_bus <- 1;
	int time_to_set_offset <- 1;
	int episode <- 0;
	int total_episode<-1000;
	int done;  //終わり-1
	int time_target;

	node_agt starting_point; //agent species
	
	graph road_network;
	graph kagayaki_network;
	graph pana_east_network;
	graph kasayama_network;
	
	map kagayaki_route;
	map kasayama_route;
	map general_speed_map;
	
	path kagayaki_path;
	path kasayama_path;
	path pana_east_path;
	
	point t1;//スタート地点
	point t2;//ゴール地点
	
	file bus_shape_kagayaki  <- file('../includes/icons/vehicles/bus_blue.png');
	file bus_shape_kasayama  <- file('../includes/icons/vehicles/bus_green.png');
	file car_shape_empty  <- file('../includes/icons/vehicles/normal_red.png');
	
	init {  
		
		create road from: shape_file_roads with:[id::int(read("id")),nblanes::int(read("lanes")),maxspeed::int(read("maxspeed")),highway::string(read("highway")),
			kasayama::int(read("kasayama")),kagayaki::int(read("kagayaki")),pana_east::int(read("pana-east"))] {
			
		    //lanes <- 1;
		    maxspeed <-  60 + (rnd(20)-10)°m/°s;// (lanes = 1 ? 30.0 : (lanes = 2 ? 50.0 : 70.0)) °km/°h;
		    
		    if(kagayaki!=1){
		    	kagayaki <- 500;//重みを極端にする
		    }
		    if(kasayama!=1){
		    	kasayama <- 500;
		    }
		    if(pana_east!=1){
		    	pana_east <- 500;
		    }
		    switch oneway {
		    	match "no" {
		    		create road {
					  	lanes <- max([1, int (myself.lanes / 2.0)]);
						shape <- polyline(reverse(myself.shape.points));
						maxspeed <- myself.maxspeed;
						geom_display  <- myself.geom_display;
						linked_road <- myself;
						
						self.kagayaki <- myself.kagayaki; 
						myself.linked_road <- self;
						
						
						if(myself.kagayaki!=1){
					    	self.kagayaki <- 500;//重みを極端にする
					    }
					    if(myself.kasayama!=1){
					    	self.kasayama <- 500;
					    }
					    if(myself.pana_east!=1){
					    	self.pana_east <- 500;
					    }								
						
					  }
					  //lanes <- int(lanes /2.0 + 0.5);
				 }
		    	match "yes" {
		    		create road {
					  	lanes <- max([1, int (myself.lanes / 2.0)]);
						shape <- polyline(reverse(myself.shape.points));
						maxspeed <- myself.maxspeed;
						geom_display  <- myself.geom_display;
						linked_road <- myself;
						myself.linked_road <- self;
						self.kagayaki <- myself.kagayaki; 
						
						if(myself.kagayaki!=1){
					    	self.kagayaki <- 500;//重みを極端にする
					    }
					    if(myself.kasayama!=1){
					    	self.kasayama <- 500;
					    }
					    if(myself.pana_east!=1){
					    	self.pana_east <- 500;
					    }
					  }
					  //lanes <- int(lanes /2.0 + 0.5);
				 }
				 match "-1" {
				 	lanes <- 1;
				 	self.linked_road <- self;
				 	shape <- polyline(reverse(shape.points));
				}
			}
			geom_display <- shape+ (2.5 * lanes);
		    maxspeed <- 60 + (rnd(20)-10)°m/°s;//maxspeed <- (lanes = 1 ? 30.0 : (lanes = 2 ? 50.0 : 70.0)) °km/°h;
		}
		
		create node_agt from: shape_file_nodes with:[is_traffic_signal::(string(read("type")) = "traffic_signals"),type::(string(read("type")))];
		starting_point <- one_of(node_agt where each.is_traffic_signal);
		
		general_speed_map <- road as_map (each::(each.shape.perimeter / (each.maxspeed)));
		
		
		/*以下数行を書き換える */
		kagayaki_route <- road as_map(each::(each.kagayaki));//重みを
		kasayama_route <- road as_map(each::(each.kasayama));
		road_network <-  (as_driving_graph(road, node_agt))with_weights general_speed_map;
		
		t1 <- (node_agt(5)).location;   //スタート地点  //5 list 4 ?  
		t2 <- (node_agt(12)).location;  //ゴール地点  //12
		
		
				
		create people number: nb_people { 
			speed <- 30 #km /#h ;
			vehicle_length <- 3.0 #m;
			right_side_driving <- true;
			proba_lane_change_up <- 0.1 + (rnd(500) / 500);
			proba_lane_change_down <- 0.5+ (rnd(500) / 500);
			location <- one_of(node_agt).location;
			security_distance_coeff <- 4.0;//(1.5 - rnd(1000) / 1000);  
			proba_respect_priorities <- 1.0 - rnd(200/1000);
			proba_respect_stops <- [0.1];
			proba_block_node <- 0.0;
			proba_use_linked_road <- 0.0;
			max_acceleration <- 0.5 + rnd(500) / 1000;
			speed_coeff <- 1.2 - (rnd(400) / 1000);
		}
		
		
		create bus number: nb_bus { 
			time_target<- 12+ rnd(13);
			max_speed <- 330°m/°s;
			real_speed <- 0 °m/°s;
			target_speed<-9 + rnd(3)°m/°s; //30
			vehicle_length <- 3.0 #m;
			location <- t1;
			time_pass <- 0;
			done <- 0;
			over <- 0;
			max_acceleration <- 0.0 ;
		}	
			
	}
    reflex stop_simulation when: episode = 1000 {
        do pause ;
    } 
	
} 

//路線バスの基本形エージェント
  species bus skills: [advanced_driving,RSkill] { 
  	  //int rand_start <-5;//rnd(12);
	  //int rand_goal <- 10;//rnd(12);
	  rgb color <- rnd_color(255);
	  bool checked <-false;
  	  node_agt target <- node_agt(12); //12
	  node_agt true_target <- node_agt(12);
	  //node_agt constant_target ;
	  node_agt bus_start;
	  int n <-1;
	  int m <- rnd(n);//乱数でバスのルートを決定
      //
      int time_pass;
	  int first_time <- 1;
	  int over;
      int check_receive <- 0;
	  unknown read_python;
	  unknown pause;
	  unknown clear;
      float reward <- 0.0;
      float acceleration ; 
      float target_speed;   //current_road.maxspeed; roads[0]
	  float elapsed_time_ratio;
	  
	action reward_calculate{
    	if(time_pass != 0){
		  if(real_speed<=target_speed){
			  reward <- 0.001 * real_speed/target_speed + (time_pass > time_target ? -1 : 1)*done;
		  }
		  else{
			  reward <- 0.001 - (real_speed - target_speed)*0.03/target_speed + (time_pass > time_target ? -1 : 1)*done;
		  }
	    }
	}
    action Python_A3C {
    	 do reward_calculate;
         elapsed_time_ratio <- time_pass/time_target;
         over <- (episode < total_episode ? 0 : 1);
         write "episode:"+episode+" . over:"+over+". done:"+ done;
         //write "rs "+real_speed+"ts " + target_speed+"etr"+ elapsed_time_ratio+"dtg"+ distance_to_goal+"r"+reward+"d"+done+"o"+over;
    	 save [real_speed, target_speed, elapsed_time_ratio, distance_to_goal,reward,done,over] //time_pass
    	                                to: "D:/Software/GamaWorkspace/Python/GAMA_intersection_data_1.csv"  type: "csv" header: false; 
    	 save [real_speed, target_speed, elapsed_time_ratio, distance_to_goal,reward,done,over] 
    	                                to: "D:/Software/GamaWorkspace/Python/GAMA_intersection_data_2.csv"  type: "csv" header: false; 
    	                                
	     file Rcode_pause<-text_file("D:/Software/GamaWorkspace/Python/R_pause.txt"); //file Rcode_clear<-text_file("D:/Software/GamaWorkspace/Python/R_clear.txt");
         file Rcode_read<-text_file("D:/Software/GamaWorkspace/Python/R_read.txt");
         do startR;
         //write "read";
	     loop s over:Rcode_read.contents{read_python<- R_eval(s);}
	     check_receive <- read_python at 0;
	     //waiting for python
	     loop while: check_receive = 0 {
	         loop s over:Rcode_pause.contents{pause<- R_eval(s);}
	         loop s over:Rcode_read.contents{read_python<- R_eval(s);}  
	         check_receive <- read_python at 0;
	      }
	      //wait over. caculate
	      acceleration  <- read_python at 1;     write"check_receive acceleration:"+acceleration;
          //clear write "clear";loop s over:Rcode_clear.contents{clear<- R_eval(s);}
	      save [0] to: "D:/Software/GamaWorkspace/Python/python_AC_1.csv"  type: "csv" header: false;//
	      save [0] to: "D:/Software/GamaWorkspace/Python/python_AC_2.csv"  type: "csv" header: false;
      }    
    
	reflex change when :current_path = nil{	
		//write "reflex change:final_target <- nil;"+nil;
		final_target <- nil;
	}
	//信号に引っかかった後の処理
	reflex time_to_go when: final_target = nil and checked = true {
		if(true_target != nil){
			target <- true_target;
			true_target <- nil;
		}
		if(m=0){
			road_network <- road_network with_weights kagayaki_route;//重みを地図に適応		
			current_path <- compute_path(graph: road_network,target: target);
		}
		if(m=1){
			road_network <- road_network with_weights kasayama_route;//重みを地図に適応
			current_path <- compute_path(graph: road_network,target: target);
		}
		final_target <- node_agt(12).location;
	}	
	//目的地（終着バスターミナル）についた時の処理  && 最初の時
	 reflex time_to_restart when:final_target = nil and checked = false{ // (final_target = nil and checked = false) or (location distance_to any_location_in(node_agt(12)))<3 #m 
	    if(first_time != 1){
            done <- 1;
            write "done!!";
         	do Python_A3C;
		    episode <- episode + 1 ; //加到1000，算完最后结果
        }
        else{
        	first_time <- 0;
        }
        write "計算";
        real_speed <- 0;
        time_pass <- 0;
        time_target <- 12+ rnd(13);
        target_speed<-9 + rnd(3)°m/°s;
        
        /*loop while:rand_start = rand_goal {
		rand_start <-rnd(12);
		rand_goal <- rnd(12);
		}*/
		location <- any_location_in(node_agt(5)); //5rand_start
		if(m=0){
			 road_network <- road_network with_weights kagayaki_route;//重みを地図に適応		
			 current_path <- compute_path(graph: road_network,target: target);
		 }
		 if(m=1){
		   road_network <- road_network with_weights kasayama_route;//重みを地図に適応
		   current_path <- compute_path(graph: road_network,target: target);
		   }  
		 //true_target <- node_agt(rand_goal);
		 //target <- node_agt(rand_goal);
		 final_target <- node_agt(12).location;	 //
		 //constant_target <- node_agt(rand_goal);
		 write "change place";
		 //done <- 0;
	} 
	
	reflex move when: current_path != nil and final_target != nil{//道が決まり、目的地が決まれば動く
	    if (episode<total_episode and done = 0 ){
           do Python_A3C;
           real_speed <- real_speed + acceleration ;  //+ acceleration //real_speed <- real_speed + 5;
           if(real_speed<=0){real_speed <- 0;}
        }
        if(episode<total_episode and done = 1){
           done<-0;//  
           do Python_A3C;
           real_speed <- real_speed + 0;  //+ acceleration //real_speed <- real_speed + 5;
           if(real_speed<=0){real_speed <- 0;}
        }
		do drive;
	    time_pass <- time_pass + 1; //done <- 0;
	}

	aspect car3D {
		if (current_road) != nil {
			point loc <- calcul_loc();
			draw box(vehicle_length, 1,1) at: loc rotate:  heading color: color;
			draw triangle(0.5) depth: 1.5 at: loc rotate:  heading + 90 color: color;	
		}
	}
	
	aspect icon {
		point loc <- calcul_loc();
			if(m =0){
			draw bus_shape_kagayaki size: vehicle_length   at: loc rotate: heading + 90 ;
			}
			if(m = 1)
				{
			draw bus_shape_kasayama size: vehicle_length   at: loc rotate: heading + 90 ;	
					}
		}
	
	point calcul_loc {
		float val <- (road(current_road).lanes - current_lane) + 0.5;
		val <- on_linked_road ? val * - 1 : val;
		if (val = 0) {
			return location; 
		} else {
			return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
		}
	}

}
/*
         	write "最後の計算";
            real_speed <- 0;
            time_pass <- 0;
            time_target <- 30+ rnd(15);
        
		    location <- any_location_in(node_agt(5));
		    if(m=0){
			     road_network <- road_network with_weights kagayaki_route;//重みを地図に適応		
			     current_path <- compute_path(graph: road_network,target: target);
		     }
		
		     if(m=1){
			     road_network <- road_network with_weights kasayama_route;//重みを地図に適応
			     current_path <- compute_path(graph: road_network,target: target);
		     }
		     final_target <- node_agt(12).location;	
		     write "change place";
		     done <- 0;*/
species road skills: [skill_road] { 
	/*create road from: shape_file_roads with:[id::int(read("id")),nblanes::int(read("lanes")),maxspeed::int(read("maxspeed")),highway::string(read("highway")),
			kasayama::int(read("kasayama")),kagayaki::int(read("kagayaki")),pana_east::int(read("pana-east"))]*/
    int id;
    int nblanes;
    string highway;
	string oneway;
	geometry geom_display;
	road riverse;
	int kasayama;
	int kagayaki;
	int pana_east;
	bool observation_mode <- true; //交通量観察モード　挙動が重いときはこれをfalseに
	int flow <- 0; //交通量
	list temp1 <- self.all_agents; // t = n -1 の交通量保持のためのリスト
	
	//交通量計測のためのメソッド	
	reflex when :observation_mode  {
		
		if((length(all_agents) - length(temp1)) > 0){
			flow <- flow + length(all_agents) - length(temp1); 		
		}	
		temp1 <- self.all_agents;
	}
	
	aspect geom {    
		draw geom_display border:  #gray  color: #gray ;
	}  
}

species node_agt skills: [skill_road_node] {
	bool is_traffic_signal;
	string type;
	int cycle <- 100; //サイクル長
	float split <- 0.5 ; //スプリット
	int counter;
	int offset <- 0;
	bool is_blue <- true;
	list<road> current_shows ; //現示
	list<node_agt> adjoin_node;//隣接交差点[東,西,南,北]
	string mode <- "independence";
	agent c1; //信号制御で止める車1
	agent c2; //信号制御で止める車2
	

	//オフセット設定（広域信号制御の際に使用）
	reflex set_offset when:time = time_to_set_offset and is_traffic_signal{
		starting_point.mode <- "start";
		loop i from: 0 to: length(starting_point.adjoin_node)-1 {
			starting_point.adjoin_node[i].offset <- 0;
		}	
	}
	
	
	//起点モード（広域信号制御の際に使用）
	reflex set_adjoinnode when: time = 0{
		if(length(self.roads_out) >1){
			loop i from: 0 to: length(self.roads_out) - 1 {
				self.adjoin_node <- self.adjoin_node + [node_agt(road(roads_out[i]).target_node)] where each.is_traffic_signal;
			}
		}
	}
	
	
	//現示の切り替えタイミング
	reflex start when:counter >= cycle*split+offset {// even (cycle)
		
			counter <- 0; 
			is_blue <- !is_blue; //
			
	} 
	
	//4叉路用信号制御処理
	reflex stop4 when:is_traffic_signal and length(roads_in) = 4
	{
		
		counter <- counter + 1;
		
		if(contains(bus,c1)){ //c1是bus吗
			bus(c1).checked <- false;
		}
	
		if(contains(bus,c2)){
			bus(c2).checked <- false;
		}
		
		if(contains(people,c1)){
			people(c1).checked <- false;
		} 
		if(contains(people,c2)){
			people(c2).checked <- false;
		}
		
		
		c1 <- nil;
		c2 <- nil;
		
		
		//現示処理（通行権付与処理）
		if (is_blue) {		
				current_shows <- [road(roads_in[0]),road(roads_in[2])];				
				}else{
				current_shows <- [road(roads_in[1]),road(roads_in[3])]; 
			}
		
		if(length(current_shows) != 0){
			if(length(current_shows[0].all_agents) != 0 ){
				c1 <- current_shows[0].all_agents[0]; 
				
				if(contains(bus,c1)){
					bus(c1).true_target <- bus(c1).target;
					bus(c1).final_target <- any_location_in(self);
					bus(c1).checked <- true;
				}
				
				if(contains(people,c1)){
					people(c1).true_target <- people(c1).target;
					people(c1).final_target <- any_location_in(self);
					people(c1).checked <- true;
				}
			}
			
			if(length(current_shows[1].all_agents) != 0){
				c2 <- current_shows[1].all_agents[0];
				
				if(contains(bus,c2)){
					bus(c2).true_target <- bus(c2).target;
					bus(c2).final_target <- any_location_in(self);
					bus(c2).checked <- true; //false;//
				}
				
				if(contains(people,c2)){
					people(c2).true_target <- people(c2).target;
					people(c2).final_target <- any_location_in(self);
					people(c2).checked <- true;
				}
			}
		}
	}
		
		
	//3叉路用信号制御処理		
	reflex stop3 when:is_traffic_signal and  length(roads_in) =  3{
		
		counter <- counter + 1;
		


		//以下初期化
		if(contains(bus,c1)){
			bus(c1).checked <- false;
		}
	
		if(contains(bus,c2)){
			bus(c2).checked <- false;
		}
		
		if(contains(people,c1)){
			people(c1).checked <- false;
		} 
		if(contains(people,c2)){
			people(c2).checked <- false;
		}
	

		c1 <- nil;
		c2 <- nil;
		
		//現示処理（通行権付与処理）
		if (is_blue) {		
				current_shows <- [road(roads_in[0])];				
				}else{
				current_shows <- [road(roads_in[1]),road(roads_in[2])]; 
			}
			
		//現示の道路に車がいない時の処理
		if(length(current_shows) != 0){
			
			if(length(current_shows[0].all_agents) != 0 ){
				c1 <- current_shows[0].all_agents[0]; 
				
				if(contains(bus,c1)){
					bus(c1).true_target <- bus(c1).target;
					bus(c1).final_target <- any_location_in(self);
					bus(c1).checked <- true;
				}
				
				if(contains(people,c1)){
					people(c1).true_target <- people(c1).target;
					people(c1).final_target <- any_location_in(self);
					people(c1).checked <- true;
				}
			}
			
			//現示の道路が二本以上の時
			if(length(current_shows) > 1){
				if(length(current_shows[1].all_agents) != 0){
					c2 <- current_shows[1].all_agents[0];
					
					if(contains(bus,c2)){
						bus(c2).true_target <- bus(c2).target;
						bus(c2).final_target <-  any_location_in(self);
						bus(c2).checked <- true;
					}
					
					if(contains(people,c2)){
						people(c2).true_target <- people(c2).target;
						people(c2).final_target <- any_location_in(self);
						people(c2).checked <- true;
					}	
				}
			}
		}
	}
	
	aspect geom3D {
		if (is_traffic_signal) {	
			draw box(1,1,10) color:rgb("black");
			draw sphere(5) at: {location.x,location.y,12} color: is_blue ? #green : #red;
		}
	}
}

	
species people skills: [advanced_driving] { 
	rgb color <- rnd_color(255);
	bool checked;
	node_agt target;
	node_agt true_target;
	
	reflex change when :current_path = nil{
		final_target <- nil;
	}
	
	
	reflex time_to_go when: final_target = nil and checked = false{
		
		target <- one_of(node_agt);
		if(true_target != nil){
		target <- true_target;
		true_target <- nil;
		}
		road_network <- road_network with_weights general_speed_map;//重みを地図に適応	
		current_path <- compute_path(graph: road_network, target: target );
		if (current_path = nil ) {
			final_target <- nil;
		}
	}
	
	reflex time_to_go_true when: final_target = nil and checked = true{	
		current_path <- compute_path(graph: road_network, target: target );
	}
	
	reflex move when: current_path != nil and final_target != nil {
		real_speed <- real_speed + 4 ;
		do drive;
	}
	aspect car3D {
		if (current_road) != nil {
			point loc <- calcul_loc();
			draw box(vehicle_length, 1,1) at: loc rotate:  heading color: color;
			draw triangle(0.5) depth: 1.5 at: loc rotate:  heading + 90 color: color;	
		}
	} 
	
	aspect icon {
		point loc <- calcul_loc();
			draw car_shape_empty size: vehicle_length   at: loc rotate: heading + 90 ;
	}
	
	point calcul_loc {
		float val <- (road(current_road).lanes - current_lane) + 0.5;
		val <- on_linked_road ? val * - 1 : val;
		if (val = 0) {
			return location; 
		} else {
			return (location + {cos(heading + 90) * val, sin(heading + 90) * val});
		}
	}
} 


experiment traffic_simulation type: gui {
	float minimum_cycle_duration<-0.4#s;
	output {
		display city_display type: opengl{
			species road aspect: geom refresh: false;
			species node_agt aspect: geom3D;
			species people aspect: icon;
			species bus aspect: icon;
		}
	}
}