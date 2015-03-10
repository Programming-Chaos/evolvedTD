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

  //DATA
  float[][] weights;
  int row_size;
  int col_size;
  
  //Default Constructor
  Brain(){
    weights = new float[100][1000];
    row_size = 10;
    col_size = 1000;
    for(int i = 0; i < 10; i++){
      for(int j = 0; j < 100; j++){
        weights[i][j] = (float)random(2);
      }
    }
  }
  
  //Custom Constructor - taking two ints
  Brain(int col, int rows, ArrayList<Trait> w){
    weights = new float[rows][col];
    row_size = rows;
    col_size = col;
    int j = 0;
    Trait t;
    Iterator<Trait> it = w.iterator();
    
    for(int i = 0; i < rows; i++){
      while(it.hasNext()){
        t = it.next();
        weights[i][j] = t.genes;
        j++;
      }  
    }  
  }
 
 //basic print function for testing
 void print_weights(){
   for(int i = 0; i < row_size; i++){
      for(int j = 0; j < col_size; j++){
         print(weights[i][j] + " ");     
      }
      println();
    }   
          println();
 }
  
}
