// Copyright (C) 2015 evolveTD Copyright Holders

/*
  Team Krang :: Brain & behavior

  Authors: Emeth Thompson
  Britany Smith

  The Brain class is a single layer neural network. Its current form
  is a 2D array/matrix of integers (outputs). For the Brain to
  create behavior an input vector will be multiplied by the matrix
  and the resulting vector will represent possible actions. These
  actions are the individual components that comprise behavior.

*/


import java.util.Iterator;
class Brain{
  static final int INPUTS = 2;  
  static final int OUTPUTS = 3;
  float threshold;
  float prev_alpha;
  float alpha;
  
  float inputs[];
  float outputs[];
  float weights[];
  
  Brain(Genome genome){
    outputs = new float[OUTPUTS];
    inputs = new float[INPUTS];
    weights = new float[OUTPUTS];
    threshold = 1;
    prev_alpha = 0;
    alpha = 0;
    
    for(int i = 0; i < OUTPUTS; i++){
      weights[i] = genome.sum(brainTraits.get(i)); 
      outputs[i] = 0;
    }
    
    for(int i = 0; i < INPUTS; i++){
      inputs[i] = 0;
    }
  }
  
  boolean activate(int i){
    if(outputs[i] >= threshold) {
      return true;
    }
    else {
      return false;
    }
  }
  
  void calc_inputs(float left, float right){
    prev_alpha = alpha;
    alpha = right - left + 100;
    
    inputs[0] = alpha - prev_alpha;
    inputs[1] = alpha;
  }
  
  float get_output(int i){
    return ((inputs[0]*weights[i] + inputs[1]*weights[i])/(alpha));
  }
} 

/*
OLD BRAIN
/*
class Brain {
  // outputs for the brain's artificial neural network
  static final int OUTPUTS = 3;
  static final int INPUTS = 2;
  static final int outputs = OUTPUTS*INPUTS;

  //DATA
  float outputs[][];

  //Custom Constructor - taking two ints
  Brain(Genome genome){
    outputs = new float[OUTPUTS][INPUTS];

    for(int i = 0; i < OUTPUTS; i++) {
      for (int j = 0; j < INPUTS; j++) {
        outputs[i][j] = genome.sum(brainTraits.get(i*INPUTS + j));
        if (j == 0 && i == 0) {
          outputs[i][j] -= 115;
        } else if (j == 1 && i == 0) {
          outputs[i][j] += 115;
        }
        
      }
    }
  }

  //basic print function for testing
  void print_outputs(){
    for(int i = 0; i < OUTPUTS; i++){
      for(int j = 0; j < INPUTS; j++){
        print(outputs[i][j] + " ");
      }
      println();
    }
    println();
  }
}*/
