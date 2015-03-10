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

class Brain {

  //DATA
  int[][] brain;
  int row_size;
  int col_size;
  
  //Default Constructor
  Brain(){
    brain = new int[100][1000];
    row_size = 10;
    col_size = 1000;
    for(int i = 0; i < 10; i++){
      for(int j = 0; j < 100; j++){
        brain[i][j] = (int)random(2);
      }
    }
  }
  
  //Custom Constructor
  Brain(int rows, int col){
    brain = new int[rows][col];
    row_size = rows;
    col_size = col;
    for(int i = 0; i < rows; i++){
      for(int j = 0; j < col; j++){
        brain[i][j] = (int)random(2);
      }
    }  
  }
 
 //basic print function for testing
 void print_weights(){
   for(int i = 0; i < row_size; i++){
      for(int j = 0; j < col_size; j++){
         print(brain[i][j] + " ");     
      }
      println();
    }   
          println();
 }
  
}
