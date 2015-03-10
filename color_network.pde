class color_network{
  static final int input_size = 8;
  static final int output_size = 4;
  static final int num_weights = input_size*output_size;
  float[] weights;
  
  color_network(Genome genome){
    weights = new float[num_weights];
    for(int i = 0; i < num_weights; i++){
      // these X weights come from the genome
      weights[i] = genome.sum(colorTraits.get(i));
    }
  }

  void calculate(float[] inputs, float[] outputs){  // note, the first input should be a 1 for the bias
    float sum = 0;
/*    outputs[0] += (inputs[0] * weights[0]) + (inputs[1] * weights[1]) - (inputs[2] * weights[2]) + (inputs[4] * weights[4]);
    outputs[1] += (inputs[5] * weights[5]) + (1/inputs[3] * weights[3]) + (inputs[0] * weights[0]);
    outputs[2] += (inputs[6] * weights[6]) + (inputs[3] * weights[3]) + (inputs[0] * weights[0]);
    outputs[3] = 1;
*/      
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
