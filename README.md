# A2C-single-car-intersection
  This is a model describing a car runs to goal in limited time with A2C algorithm.
  The car will learn to control its accelerate with the restructions shown below:
  
  Reward shaping:
  rt = r terminal + r danger + r speed
  r terminal：-1：crash / time expires
              0:non-terminal state
  r speed： related to the target speed
  if sa ≤st: sa/st*kp;
  if sa > st: kp - (sa-st)/st*kn.

  In my experiment I set ky = ks = 0.05,kp = 0.001,kn = 0.03. 
  
  The GAMA platform has a modle "simple_intersection.gaml", which is assigned a car and some traffic lights. The model will sent some data
[real_speed, target_speed, elapsed_time_ratio, distance_to_goal,reward,done,time_pass,over] as a matrix to python environment, in which the cat's accelerate will be calculated.
  
  The interaction between the GAMA platform and python's environment is build by csv files. So GAMA model needs to use R-plugin and the R environment needs package "reticulate" to connect with python (however I use python usually).
