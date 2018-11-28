/**
* Name: Stages
* Author: giulioma
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model StagesCreative

global {
    int NB_STAGES <- 4;
    int NB_PARTICIPANTS <- 100;
    
    int NB_CYCLES <- 650;
    
    int LONELY_THRESHOLD <- 10;
    int CROWDED_PARTY <- 10;
    
	point stage_location1 <- {25,25};
	point stage_location2 <- {75,25};	
	point stage_location3 <- {75,75};
    point stage_location4 <- {25,75};
    
    
    //Leader Stuff
	list<int> stageCrowd <- [0,0,0,0];
	int people_met <- 0;
	Participant Leader <- nil;
	point meeting_point <- {50,50};
    list<Participant> meetingPointList;
    
    //VIP stuff 
    point sitting_room <- {50, 90};
    bool VipInDaHuse <- false;
    point VipStage;
    
	int cnt <- 0;
    
	list<point> stage_position <- [{25,25}, {75,25}, {75,75}, {25,75}];
	list<Stage> ALL_STAGES;
    
    init{
        create Stage number: NB_STAGES;
        create Participant number: NB_PARTICIPANTS;
        create VIP number: 1;
    }    
}

species Stage{
	
	rgb color <- #blue;
	bool initialized <- false;
	
	int myCycles <- 0;
	
	float music <- rnd(0.0,1.0);
	float lights <- rnd(0.0,1.0);
	float visuals <- rnd(0.0,1.0);
	float fireworks <- rnd(0.0,1.0);
	float dancers <- rnd(0.0,1.0);
	
	aspect base {
		if !self.initialized{
			self.initialized <- true;
			location <- stage_position[cnt];
			cnt <- cnt +1;
			add self to: ALL_STAGES;
		}
				
		draw box(2,2,2) at: location color: self.color;
	}
	
	reflex revaluate{
		if self.myCycles > NB_CYCLES{
			write "The party has changed";
			
			music <- rnd(0.0,1.0);
			lights <- rnd(0.0,1.0);
			visuals <- rnd(0.0,1.0);
			fireworks <- rnd(0.0,1.0);
			dancers <- rnd(0.0,1.0);
			
			self.myCycles <- 0;
		}
		else{
			self.myCycles <- self.myCycles + 1;
		}
	}

}

species VIP skills:[moving]{
	int myCycles <- 0;
	
	aspect base {
		draw circle(2) color: #orange;
	}
	
	reflex moveHome when: !VipInDaHuse{
		do goto target:sitting_room speed: 1;	
	}
	
	reflex selectStage{
		if self.myCycles >= NB_CYCLES{
			// chance of vip showing up
			if rnd(0, 100) > 30{
				VipInDaHuse <- true;
				VipStage <- stage_position[rnd(0, length(stage_position)-1)];
			} else{
				VipInDaHuse <- false;
			}
			self.myCycles <- 0;
		}
		else{
			self.myCycles <- self.myCycles + 1;
		}
	}
	
	reflex moveToStage when: VipInDaHuse{
		do goto target:VipStage speed: 1;
	}
}

species Participant skills:[moving]{
	
	float music <- rnd(0.0,1.0);
	float lights <- rnd(0.0,1.0);
	float visuals <- rnd(0.0,1.0);
	float fireworks <- rnd(0.0,1.0);
	float dancers <- rnd(0.0,1.0);
	
	bool crowdMass <- false; //masser
	
	int myCycles <- 0;
	
	list<float> stage_memory;
	list<point> nearest_stages <- stage_position;
	
	Stage TargetStage;
	point TargetStagePoint;
	bool stageSelected <- false;
	bool stageConfirmed <- false;
	
	bool IamLeader <- false;
	
	rgb color <- #blue;
	bool initialized <- false;
	
	init{
		nearest_stages <- nearest_stages sort_by (location distance_to each);
	}
	
	int stages_visited <- 0;
	
	aspect base {
		if !self.initialized{
			if rnd(0,100) > 10{
				color <- #green;
				crowdMass <- true;
			} else{
				color <- #red;
			}
			
			self.initialized <- true;
		}
		
		draw circle(1.0) color: color;
	}
	
	reflex visit_stage when: self.stages_visited < NB_STAGES{
		point target <- self.nearest_stages[self.stages_visited];
		if location distance_to target > 2{
			do goto target:target speed: 1.0;
		} 
		else{	
			loop a over:ALL_STAGES{
				if a.location = target{
					ask a{
						float utility <- (self.music*myself.music) + (self.lights*myself.lights) 
							+ (self.visuals*myself.visuals) + (self.fireworks*myself.fireworks)
							+ (self.dancers*myself.dancers);
							
						add utility to: myself.stage_memory;
					}
					break;
				}
			}
			
			self.stages_visited <- self.stages_visited + 1;
		}
	}
	
	reflex chooseStage when: self.stages_visited = NB_STAGES and !self.stageSelected and !self.stageConfirmed{
		float max_stage_val <- -1.0;
		point selectedStagePoint;
		loop a from: 0 to: length(self.stage_memory)-1{
			if max_stage_val < self.stage_memory[a]{
				max_stage_val <- self.stage_memory[a];
				selectedStagePoint <- self.nearest_stages[a];
			}
		}
		
		loop a over:ALL_STAGES{
			if a.location = selectedStagePoint{
				TargetStage <- a;
				TargetStagePoint <- selectedStagePoint;
				self.stageSelected <- true;
				write "Going to stage: " + TargetStagePoint + " with utility: " + max_stage_val;
				break;
			}
		}
	}
	
	reflex moveToStageSelected when: self.stageConfirmed and self.stageSelected{
		if location distance_to TargetStagePoint > 2 {
			do goto target:TargetStagePoint speed: 1.0;
		}
	}
	
	reflex resetStages{
		if self.myCycles > NB_CYCLES{
			self.stages_visited <- 0;
			self.stageSelected <- false;
			self.stageConfirmed <- false;
			self.stage_memory <- [];
			self.myCycles <- 0;
		}
		else{
			self.myCycles <- self.myCycles + 1;
		}
	}
	
	reflex goToMeetingPoint when: self.stageSelected and !self.stageConfirmed{
		
		if location distance_to meeting_point > 2 {
			do goto target:meeting_point speed: 1.0;
		} 
		else{
			
//			list<int> stageCrowd <- [0,0,0,0];
//			int people_met <- 0;
//			Participant Leader <- nil;
//			point meeting_point <- {50,50};
//		    	list<Participant> meetingPointList;
			
			if Leader = nil and self.crowdMass{
				Leader <- self;
			}
			
			if !(meetingPointList contains self){
				add self to: meetingPointList;
				people_met <- people_met + 1;
				loop i from:0 to: length(stage_position)-1{
					if self.TargetStagePoint = stage_position[i]{
						stageCrowd[i] <- stageCrowd[i]+1;
						break;
					}
				}
			}
			
			if Leader = self and people_met >= NB_PARTICIPANTS{
				loop p over: meetingPointList{
					if p != self {
						ask p{
							if !self.crowdMass{
								//Suggest a low crowd stage
								point suggestedPoint;
								loop i from:0 to:length(stageCrowd)*8{
									int rand <- rnd(0, length(stageCrowd)-1);
									suggestedPoint <- stage_position[rand];
									if stageCrowd[rand] < CROWDED_PARTY{
										break;
									}
								}
								
								//Check if Vip-in-da-huse
								if VipInDaHuse{
									suggestedPoint <- VipStage;
								}
								
								//Convert point to stage
								Stage suggestedStage;
								loop s over: ALL_STAGES{
									ask s{
										if location = suggestedPoint{
											suggestedStage <- self;
											break;
										}
									}
								}
								
								//Update the preference
								self.TargetStage <- suggestedStage;
								self.TargetStagePoint <- suggestedPoint;
								self.stageSelected <- true;	
								self.stageConfirmed <- true;
							} 
							else{
								//Find target crowd
								int targetStageCrowd;
								loop i from:0 to:length(stage_position)-1{
									if self.TargetStagePoint = stage_position[i]{
										targetStageCrowd <- stageCrowd[i];
									}
								}
								
								if targetStageCrowd < CROWDED_PARTY or VipInDaHuse{
									//Suggest a high crowd stage
									point suggestedPoint;
									loop i from:0 to:length(stageCrowd)*100{
										int rand <- rnd(0, length(stageCrowd)-1);
										suggestedPoint <- stage_position[rand];
										if stageCrowd[rand] > CROWDED_PARTY{
											break;
										}
									}
									
									//Check if Vip-in-da-huse
									if VipInDaHuse{
										suggestedPoint <- VipStage;
									}
									
									//Convert point to stage
									Stage suggestedStage;
									loop s over: ALL_STAGES{
										ask s{
											if location = suggestedPoint{
												suggestedStage <- self;
												break;
											}
										}
									}
									
									self.TargetStage <- suggestedStage;
									self.TargetStagePoint <- suggestedPoint;
								}
								
								//Update the preference
								self.stageSelected <- true;	
								self.stageConfirmed <- true;
							}
						}
					}
				}
				
				stageCrowd <- [0,0,0,0];
				people_met <- 0;
				Leader <- nil;
		    	meetingPointList <- [];
		    	
		    	// For Leader Check if Vip-in-da-huse
				if VipInDaHuse{
					point suggestedPoint <- VipStage;
					//Convert point to stage
					Stage suggestedStage;
					loop s over: ALL_STAGES{
						ask s{
							if location = suggestedPoint{
								suggestedStage <- self;
								break;
							}
						}
					}
					
					self.TargetStage <- suggestedStage;
					self.TargetStagePoint <- suggestedPoint;
				}
		    	
		    	self.stageSelected <- true;	
				self.stageConfirmed <- true;
			}
		}
	}
}

experiment stage_info type: gui {
    output {
        display main_display {
            species Stage aspect: base ;
            species Participant aspect:base;
            species VIP aspect:base;
            
            graphics 'sitting_room'{
				draw box(4,6,4) color: #orange at: sitting_room;
			}
        }
    }
}