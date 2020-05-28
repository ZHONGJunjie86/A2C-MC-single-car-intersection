import matplotlib.pyplot as plt
import numpy as np
import time,random
import os 

from_GAMA_1 = 'D:/Software/GamaWorkspace/Python/GAMA_intersection_data_1.csv'
from_GAMA_2 = 'D:/Software/GamaWorkspace/Python/GAMA_intersection_data_2.csv'
from_python_1 = 'D:/Software/GamaWorkspace/Python/python_AC_1.csv'
from_python_2 = 'D:/Software/GamaWorkspace/Python/python_AC_2.csv'
def reset():
    f=open(from_GAMA_1, "r+")
    f.truncate()
    f=open(from_GAMA_2, "r+")
    f.truncate()
    f=open(from_python_1, "r+")
    f.truncate()
    f=open(from_python_2, "r+")
    f.truncate()
    return_ = [0]
    np.savetxt(from_python_1,return_,delimiter=',')
    np.savetxt(from_python_2,return_,delimiter=',')

def compute_returns(last_value, rewards, masks, gamma=0.99):
    R = last_value
    returns = []
    for step in reversed(range(len(rewards))):
        R = rewards[step] + gamma * R * masks[step]
        returns.insert(0, R)
    return returns

def cross_entropy_curve(entropys,total_rewards):
    plt.plot(np.array(entropys), c='b', label='cross_entropy')
    plt.plot(np.array(total_rewards), c='r', label='total_rewards')
    plt.legend(loc='best')
    plt.ylabel('cross_entroy')
    plt.xlabel('training steps')
    plt.grid()
    plt.show()

def GAMA_connect(test):
    try:
        while (os.path.exists(from_GAMA_1)==False):
            time.sleep(0.05) # deadlock
        while(os.path.exists(from_GAMA_1)==False or
              os.stat(from_GAMA_1).st_size == 0):
            time.sleep(0.05)
        while (os.path.exists(from_GAMA_2)==False):
            time.sleep(0.05) # deadlock
        while(os.path.exists(from_GAMA_2)==False or
              os.stat(from_GAMA_2).st_size == 0):
            time.sleep(0.05)
        if(random.random()>0.3):
            state = np.loadtxt(from_GAMA_1, delimiter=",")
        else:
            state = np.loadtxt(from_GAMA_2, delimiter=",")
        time_pass = state[2]
    except (IndexError,FileNotFoundError):
        time.sleep(0.05)
        try:
            if(random.random()>0.3):
                state = np.loadtxt(from_GAMA_1, delimiter=",")
            else:
                state = np.loadtxt(from_GAMA_2, delimiter=",")
            time_pass = state[2]
        except (IndexError,FileNotFoundError):
            time.sleep(0.05)
            try:
                if(random.random()>0.3):
                    state = np.loadtxt(from_GAMA_1, delimiter=",")
                else:
                    state = np.loadtxt(from_GAMA_2, delimiter=",")
                time_pass = state[2]
            except (IndexError,FileNotFoundError):
                time.sleep(0.07)
                if(random.random()>0.3):
                    state = np.loadtxt(from_GAMA_1, delimiter=",")
                else:
                    state = np.loadtxt(from_GAMA_2, delimiter=",")
                time_pass = state[2]
    reward = state[4]
    done = state[5]  # time_pass = state[6]
    over = state [6] 
    print("Recived:",state," done:",done)
    state = np.delete(state, [4,5,6], axis = 0)
           
    f1=open(from_GAMA_1, "r+")
    f1.truncate()
    f2=open(from_GAMA_2, "r+")
    f2.truncate()
    return state,reward,done,time_pass,over,