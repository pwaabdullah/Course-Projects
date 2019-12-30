package com.mkyong.csv;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;

public class CSVReader {

    public static void main(String[] args) {
    	//after fuzzification 
        String csvFile = "/Users/mamun/csv/FuzzificationResult.csv";
        String line = "";
        String cvsSplitBy = ",";
        double alphaCut = 0.15;
        float ID=0, petalLength=0, pl1=0, pl2=0, pl3=0, c1=0, c2=0, c3=0;

        try (BufferedReader br = new BufferedReader(new FileReader(csvFile))) {

            while ((line = br.readLine()) != null) {
            	// use comma as separator
                String[] str = line.split(cvsSplitBy);
                ID = Float.valueOf(str[0]);
                petalLength = Float.valueOf(str[1]);
                pl1 = Float.valueOf(str[2]);
                pl2 = Float.valueOf(str[3]);
                pl3 = Float.valueOf(str[4]);                

                if(pl1 <= alphaCut){
                	pl1 = 0;
                	}	
                else {
                	pl1=1;
                	}
                if(pl2 <= alphaCut){
                	pl2 = 0;
                	}	
                else {
                	pl2=1;
                	}
                if(pl3 <= alphaCut){
                	pl3 = 0;
                	}	
                else {
                	pl3=1;
                	}
    
                if (pl1 == 1){
                	c1 = ID;
                }
                if (pl2 == 1){
                	c2 = ID;
                }
                if (pl3 == 1){
                	c3 = ID;
                }
                System.out.println("Object [ID= " + ID + " , Petal Length=" + petalLength + ", Pl1=" + pl1 + ", Pl2=" + pl2 + ", Pl3=" + pl3 + "]");
                System.out.println("Object [Context1 = " + c1 + " , context2=" + c2 + ", context3=" + c3 + "]");
                
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
        
        

    }
}