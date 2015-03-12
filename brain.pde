/*
  Team Krang :: Brain & behavior

  Authors: Emeth Thompson
  Britany Smith

  The Brain class is a single layer neural network. Its current form
  is a 2D array/matrix of integers (weights). For the Brain to
  create behavior an input vector will be multiplied by the matrix
  and the resulting vector will represent possible actions. These
  actions are the individual components that comprise behavior.

*/


import java.util.Iterator;

class Brain {
  // Weights for the brain's artificial neural network
  static final int OUTPUTS = 2;
  static final int INPUTS = 1000;
  static final int WEIGHTS = OUTPUTS*INPUTS;

  //DATA
  float weights[][];

  //Custom Constructor - taking two ints
  Brain(Genome genome){
    weights = new float[OUTPUTS][INPUTS];

    for(int i = 0; i < OUTPUTS; i++) {
      for (int j = 0; j < INPUTS; j++) {
        weights[i][j] = genome.sum(brainTraits.get(i*INPUTS + j));
      }
    }
  }

  //basic print function for testing
  void print_weights(){
    for(int i = 0; i < OUTPUTS; i++){
      for(int j = 0; j < INPUTS; j++){
        print(weights[i][j] + " ");
      }
      println();
    }
    println();
  }
}
