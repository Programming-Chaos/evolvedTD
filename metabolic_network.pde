
/* Defines the network for controlling metabolism
   The creature has three energy "pools": one for reproduction, one for locomotion, and one for health.
   The role of the metabolic network is to decide how much energy goes to each.
   The metabolic network is just a perceptron network.
   inputs (4): 
   current levels of energy in the reproduction, locomotion, and health energy stores (3)
   age (1)
   bias(1)
   outputs (3):
   ratio of obtained energy (after eating food) that goes to each energy "pool"
*/
   

class metabolic_network{
  int input_size;
  int output_size;
  float[] weights;
  int num_weights;
  
  metabolic_network(){
    input_size = 5;
    output_size = 3;
    num_weights = input_size*output_size;
    weights = new float[num_weights];
    for(int i = 0; i < num_weights; i++){
      weights[i] = randomGaussian();  // these X weights will come from the genome
    }
  }
  
  void calculate(float[] inputs, float[] outputs){  // note, the first input should be a 1 for the bias
    float sum = 0;
    for(int outs = 0; outs < output_size; outs++){
      outputs[outs] = 0;
      for(int i = 0; i < input_size; i++){
        outputs[outs] += (inputs[i] * weights[outs*input_size+ i]);
      }
    }
  }
  
  int getNumInputs(){
    return input_size;
  }
  
  int getNumOutputs(){
    return output_size;
  }
  
}
