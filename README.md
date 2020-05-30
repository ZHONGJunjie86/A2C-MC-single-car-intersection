# A2C-single-car-intersection
   This is a model describing a car runs to goal in limited time using A2C algorithm to control its speed.    
   My purpose is building a architecture at frist, for the futureBy the A2C i wrote I'll write a A3C model in the next time, in which I'll complete a multi-agents system(MAS).
# Reward shaping
   The work I did now is very simple. 
  
   The car will learn to control its accelerate with the restructions shown below:  
   Reward shaping:  
     rt = r terminal + r danger + r speed  
     r terminal：-1：crash / time expires  
                 0:non-terminal state  
     r speed： related to the target speed  
   if sa ≤st: sa/st*kp;  
   if sa > st: kp - (sa-st)/st*kn.  

  In my experiment I set ky = ks = 0.05,kp = 0.001,kn = 0.03.   
# About GAMA
   The GAMA is a platefrom to do simulations.
   I have a GAMA-modle "simple_intersection.gaml", which is assigned a car and some traffic lights. The model will sent some data  
   [real_speed, target_speed, elapsed_time_ratio, distance_to_goal,reward,done,time_pass,over]  
   as a matrix to python environment, in which the car's accelerate will be calculated by A2C. And applying to the Markov Decision Process framework, the car in the GAMA will take up the accelerate and send the latest data to python again and over again until  reaching the destination.
# Architecture
   The interaction between the GAMA platform and python's environment is build by csv files. So GAMA model needs to use R-plugin and the R environment needs package "reticulate" to connect with python (I use python more usually).
                              
                      
  ![image](https://github.com/ZHONGJunjie86/A3C-single-car-intersection/blob/master/illustrate/illustrate.gif )   
  ![image](https://github.com/ZHONGJunjie86/A3C-single-car-intersection/blob/master/illustrate/A2C-Architecture.JPG) 
  ![image](https://github.com/ZHONGJunjie86/A3C-single-car-intersection/blob/master/illustrate/A3C-Architecture.JPG) 
