

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Random;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/* TRANSFORMER working with a boolean type based formal context
 * This one supports package sized reduction where LR is used after 
 * after every "package size" object insertions when building the RFC
 * 
 * Has code from Eman about calculating similarity metrics for both 
 * number and string values to match by approximation and then use a
 * threshold percentage cutoff to set RFC values to 0 or 1
 */

public class Transformer_B2_approx 
{
	// static variables don't need a constructor to be initialized

	// make a two dimensional arraylist to contain our dataset table
	private static ArrayList<ArrayList<String>> dataset = new ArrayList<ArrayList<String>>();

	// another 2d arraylist for the formal context
	private static ArrayList<ArrayList<Boolean>> formalContext = new ArrayList<ArrayList<Boolean>>();

	// this one saves the object names in the first column of the the formal context table
	// eg: obj1-obj2,obj1-obj3, obj2-obj3, etc...
	private static ArrayList<String> fcObjectNames = new ArrayList<String>();

	// a simple arraylist to save the attribute names separately from the CSV file
	private	static ArrayList<String> attributeNames = new ArrayList<String>();

	// A simple arraylist to save the attribute names separately from the FC file.
	// this is only used if we are reading the FC file directly, else the above variable
	// already has the names if we read the CSV file
	private	static ArrayList<String> fcAttributeNames;

	// this one holds the functional dependencies
	private	static ArrayList<ArrayList<Integer>> fdTable;
	/* fdTable design
	 * 
	 * INPUT from fd file:
	 * [chess.csv.column2]-->chess.csv.column1
	 * [chess.csv.column2]-->chess.csv.column3
	 * [chess.csv.column1, chess.csv.column2, chess.csv.column3, chess.csv.column4, chess.csv.column5, chess.csv.column6]-->chess.csv.column7
	 * 
	 * RESULTANT OUTPUT in fdTable memory:
	 * 2,1
	 * 2,3
	 * 1,2,3,4,5,6,7
	 * 
	 * Note: the right side of the fd is always the last element in the integer list
	 */
	private static int skipFirstColumn;
	private static int skipLastColumn;
	private static double globalSimilarityThreshold;
	
	public static void main(String[] args) throws ClassNotFoundException 
	{
		System.out.println("RUNNING TRANSFORMER_B_2_approximation");
		Instant programStart = Instant.now();
		LocalDateTime ldt = LocalDateTime.ofInstant(programStart, ZoneId.systemDefault());
		System.out.printf("Started on %s %d %d at %d:%d%n", ldt.getMonth(), ldt.getDayOfMonth(),
				ldt.getYear(), ldt.getHour(), ldt.getMinute());

		// stepred/breast-cancer-wisconsin, bcw_s200_10_O
		// sample/bcw_s200_5.csv
		// dhoha/mr800_s1000.csv
		String datasetFile = "abalone.csv";	// set the input dataset file here mamun
		int reduceAfterInsertions = 30;
		globalSimilarityThreshold = 90.0;	// set the fuzzy threshold over here
		
		// rfc = Reduced Formal Context
		// rdb = Reduced Database objects created from the rfc
		// both rfc and rdb are written to the same folder as original dataset name and have extra characters "FC"
		// and "_R" attached to the files respectively
		int write_RFC = 1; 		// set to 1 to write the reduced FC, 0 otherwise
		int write_RDB = 0; 		// set to 1 to write the reduced DB objects from the reduced FC, 0 otherwise
		skipFirstColumn = 0;	// set to 1 if the dataset has unique id values in the first column, 0 otherwise
		skipLastColumn = 0;		// set to 1 if the dataset has class labels in the last column that should not be 
		// transformed into FC, 0 otherwise

		readCsvFile(datasetFile);
		//System.out.println("Size of dataset : " + dataset.size());
		//printDataset();
		//createSampleFile(datasetFile, 100);
		//convertToFullFC();
		//writeFCtoFile(datasetFile);
		//Instant start = Instant.now();
		
		
		// choose the proper function to get either strict equality FC or fuzzy approximate FC
		convertToReducedFC(reduceAfterInsertions);
		//convertToApproximateReducedFC(reduceAfterInsertions);

		
		
		//ArrayList<Integer> reducedRows = LukasiewiczReduction(1);
		//removeRows(reducedRows);
		System.out.println("Size of FC : " + formalContext.size());
		if (write_RFC == 1)
			writeFCtoFile(datasetFile);
		
		/*
		readFCFile(datasetFile);
		printFC();	
		System.out.println("Size of FC : " + formalContext.size());
		if (write_RFC == 1)
			writeFCtoFile(datasetFile);
		ArrayList<Integer> dbObjects = new ArrayList<Integer>();
		dbObjects = buildDBfromReducedFC(fcObjectNames);
		// print the rebuilt database object indexes
		System.out.println("DB Objects : " + dbObjects);
		System.out.println("Size of reduced DB : " + dbObjects.size());
		if (write_RDB == 1)
			writeReducedDBtoFile(dbObjects, dataset, attributeNames, datasetFile);
		Instant end = Instant.now();
		System.out.println("Time Taken : " + Duration.between(start, end));
		//	*/	
		//dumpFCtoFile(datasetFile);

/*			
		String formalContextFile = "Benchmark_csv/brock200_1.clq.csv";
		readFCFile(formalContextFile);
		System.out.println("Size of FC before reduction: " + formalContext.size());
		//printFC();
		//writeFCtoFile("sample/bcw_s100_2FC.csv");
		Instant start = Instant.now();
		ArrayList<Integer> reducedRows = LukasiewiczReduction(1);
		//System.out.println(reducedRows);
		System.out.println("Reduction % : " + calcRemovedObjectsPercentage(reducedRows.size()));
		removeRows(reducedRows);
		Instant end = Instant.now();
		System.out.println("Time Taken to reduce the full FC: " + Duration.between(start, end));
		System.out.println(formalContext.size());
	*/	
		/*
		ArrayList<Integer> dbObjects;
		dbObjects = buildDBfromReducedFC(fcObjectNames);
		System.out.println("Size of reduced DB : " + dbObjects.size());
		//writeReducedDBtoFile(dbObjects, dataset, attributeNames, datasetFile);
//		*/

		//printFC();
		//writeFCtoFile("stepred/breast-cancer-wisconsin_fullFCreduced.csv");
		//		System.out.println(InverseLukasiewiczReduction(1));

		//readFDFile("tane_signal processing scopus.txt");
		//checkFdValidity();

		System.out.println("DONE");
	}

	public static void readCsvFile(String fileName) 
	{
		if (fileName.equals(""))
			return;

		System.out.println("Reading dataset : " + fileName);
		BufferedReader fileReader = null;
		String[] tokens;
		int i=0,j, datasetRow, numColumns;

		try 
		{
			String line = "";

			// Create the file reader
			fileReader = new BufferedReader(new FileReader(fileName));

			// Read the CSV file header to read columns names or skip it
			// we can use this to skip the header line containing the column names if required
			line = fileReader.readLine();

			// extract all the column names from the first line
			tokens = line.split(",|;");
			if (tokens.length > 0)
			{
				for (i = 0; i < tokens.length; i++)
				{
					attributeNames.add(tokens[i]);
					//System.out.print(tokens[i] + " ");
				}
			}
			numColumns = i;
			fcAttributeNames = attributeNames ;

			datasetRow = 0;			
			// Read the file line by line starting from the second line
			while ((line = fileReader.readLine()) != null) 
			{
				// Get all tokens available in line
				tokens = line.split(",|;");  // some datasets use semicolons as delimiters, so we put support for both , and ;
				if (tokens.length > 0) 
				{
					// insert all tokens into a single inner line of the 2d arraylist
					/* 0 [] []        <- list to put tokens into
					 * 1 []
					 * 2 []
					 * */

					// add a new row in the 2d array for next line in dataset
					dataset.add(new ArrayList<String>());

					// iterate through tokens and add them to the 2d array
					for (i = 0; i < tokens.length; i++)
					{
						//some datasets use "?" to mark missing data so we handle that case
						if (tokens[i].equalsIgnoreCase("?"))
						{
							dataset.get(datasetRow).add("");
						}
						else
						{
							dataset.get(datasetRow).add(tokens[i]);
						}
					}
					// add empty tokens for missing data at end of the line
					for (j=0;j<numColumns-i;j++)
					{
						dataset.get(datasetRow).add("");
					}
				}
				// Point to the next line in the 2d arraylist
				/* 0 [] [] [] [] [] [] []
				 * 1 []         <- list to setup for next group of tokens
				 * 2 []
				 * */
				datasetRow++;
			}
		} 
		catch (Exception e) 
		{
			System.out.println("Error in CsvFileReader !!!");
			e.printStackTrace();
		} 
		finally 
		{
			try 
			{
				fileReader.close();
			} 
			catch (IOException e) 
			{
				System.out.println("Error while closing fileReader of CSV!!!");
				e.printStackTrace();
			}
		}
	}

	/*
	 * Creates a smaller sample from the original dataset and writes it to a file
	 * with the filename format : <dataset_filename>_s<sampleSize>_<identifier>.csv
	 * 
	 * eg: if the dataset filename is "abalone10.csv"
	 * the filenames for the sample size 5 are created are :
	 * abalone10_s5_1
	 * abalone10_s5_2
	 * abalone10_s5_3
	 * and so on...
	 */
	public static void createSampleFile(String datasetFileName, int sampleSize) 
	{
		if (sampleSize <=0)
		{
			System.out.println("Invalid sample size given : " + sampleSize);
			return;
		}
		else if (dataset.size() <=0)
		{
			System.out.println("Dataset not set up before sampling");
			return;
		}

		Random randomGenerator = new Random();
		int i, j, randomInt;
		FileWriter writer = null;
		String line;

		// create sample filename from name of original dataset file
		String outputFileName = "";
		i = datasetFileName.lastIndexOf('.');
		outputFileName += datasetFileName.substring(0, i) + "_"; // copy only filename and not extension
		outputFileName += "s" + (sampleSize) + "_";

		/* Add number suffix to duplicate file names to keep each sample unique
		 * e.g. base file name is "abalone_s100"
		 * then the output files are : 
		 * "abalone_s100_1"
		 * "abalone_s100_2"
		 * "abalone_s100_3"
		 * And so on ...
		 */
		Pattern p = Pattern.compile("^(.*)(_s\\d*_?)(\\d*)");
		do{
			Matcher m = p.matcher(outputFileName);
			if(m.matches())
			{
				// Group 1 is the dataset filename, 
				// Group 2 is "_s<sampleSize>_"
				outputFileName = m.group(1) + m.group(2); 
				// Group 3 is an identifier of sequential number order so to prevent
				// overwriting older sample files created
				if (m.group(3) == null || m.group(3).equals(""))
				{
					outputFileName+= "1";
				}
				else
				{
					outputFileName+= Integer.parseInt(m.group(3)) + 1;
				}
			}
		}while(new File(outputFileName+".csv").exists());//repeat until a new filename is generated
		outputFileName += (".csv");
		System.out.println("Creating sample file: " + outputFileName + " of size : " + sampleSize);

		try 
		{
			line = "";

			// Create the file reader
			writer = new FileWriter(outputFileName);

			// Write the attribute names of the dataset in the first line
			for (i = 0; i < attributeNames.size(); i++)
			{
				// The concat() method returns a new String that contains the result of the operation
				// It does not change the string itself so line.concat does not work, line = line.concat is valid
				line = line.concat(attributeNames.get(i).toString());
				if (i != attributeNames.size()-1)
					line = line.concat(",");
			}
			line = line.concat("\n");
			//System.out.print(line);
			writer.append(line);

			for (i = 0; i < sampleSize; i++)
			{
				line = "";
				randomInt = randomGenerator.nextInt(dataset.size());
				//System.out.println(randomInt);
				for (j = 0; j<dataset.get(randomInt).size(); j++)
				{
					line = line.concat(dataset.get(randomInt).get(j));
					if (j != dataset.get(randomInt).size()-1)
						line = line.concat(",");
				}
				line = line.concat("\n");
				//System.out.print(line);
				writer.append(line);
			}
		} 
		catch (Exception e) 
		{
			System.out.println("Exception in createSampleFile");
			e.printStackTrace();
		} 
		finally
		{
			try 
			{
				writer.flush();
				writer.close();
			} 
			catch (IOException e) 
			{
				System.out.println("IO Exception in createSampleFile");
				e.printStackTrace();
			}
		}
	}


	public static void convertToFullFC()
	{
		System.out.println("Start convertion to Full FC");
		int i, j, k, fcRow;
		ArrayList<String> compareObj1, compareObj2;

		if (dataset.size() <=0)
		{
			System.out.println("Dataset not set up before converting to Full FC");
			return;
		}

		fcRow = 0;
		for (i = 0; i < dataset.size()-1; i++)
		{
			compareObj1 = dataset.get(i);
			// Reflexivity case where obj1-obj1 is also included, set j=i
			// Standard case to always compare non-matching objects is to set j = i+1
			for (j = i+1; j<dataset.size(); j++)
			{
				compareObj2 = dataset.get(j);

				// add a new row to fc
				formalContext.add(new ArrayList<Boolean>());
				fcObjectNames.add("obj" + (i+1) + "-obj" + (j+1));

				// compare the data in the two objects for each attribute
				for (k = 0; k < compareObj1.size(); k++)
				{
					//System.out.println("Comparing " + compareObj1.get(k) + " and " + compareObj2.get(k));
					if (compareObj1.get(k).equals(compareObj2.get(k)))
					{
						if (compareObj1.get(k).length() == 0)
						{
							formalContext.get(fcRow).add(false);
						}
						else
						{
							formalContext.get(fcRow).add(true);
						}
					}
					else
					{
						formalContext.get(fcRow).add(false);
					}
				}
				fcRow++;
			}
		}	
		// just simple code to add the last row where we compare one object to itself
		// and so would have all 1s in this row
		// eg: obj500-obj500 1 1 1 1 1 1 1 1
		i = dataset.size()-1;
		j = i;
		compareObj1 = dataset.get(i);
		compareObj2 = dataset.get(j);
		formalContext.add(new ArrayList<Boolean>());
		fcObjectNames.add("obj" + (i+1) + "-obj" + (j+1));
		for (k = 0; k < compareObj1.size(); k++)
		{
			if (compareObj1.get(k).equals(compareObj2.get(k)))
			{
				if (compareObj1.get(k).length() == 0)
				{
					formalContext.get(fcRow).add(false);
				}
				else
				{
					formalContext.get(fcRow).add(true);
				}
			}
			else
			{
				formalContext.get(fcRow).add(false);
			}
		}
	}

	public static void convertToReducedFC(int reduceAfterInsertions)
	{
		System.out.println("Start convertion to reduced FC");
		System.out.println("Applying reduction after every  " + reduceAfterInsertions + "  object Insertions");
		int i, j, k, fcRow, insertionCounter;
		ArrayList<String> compareObj1, compareObj2;
		ArrayList<Integer> reducedRows;
		int startColumn = (skipFirstColumn>=1)?1:0;


		if (dataset.size() <=0)
		{
			System.out.println("Dataset not set up before converting to reduced FC");
			return;
		}
		if (reduceAfterInsertions <=0)
		{
			System.out.println("Invalid value put for no of insertions before reduction is applied");
			return;
		}

		fcRow = 0;
		insertionCounter = 0;
		for (i = 0; i < dataset.size()-1; i++)
		{
			compareObj1 = dataset.get(i);
			if (i% 1000 == 0)
				System.out.print(i + ",");
			if (i% 20000 == 0)
				System.out.println();
			// Standard case to always compare non-matching objects is to set j = i+1
			for (j = i+1; j<dataset.size(); j++)
			{
				compareObj2 = dataset.get(j);

				// add a new row to fc
				formalContext.add(new ArrayList<Boolean>());
				fcObjectNames.add("obj" + (i+1) + "-obj" + (j+1));

				// compare the data in the two objects for each attribute
				for (k = startColumn; k < compareObj1.size()-skipLastColumn; k++)
				{
					//System.out.println("Comparing " + compareObj1.get(k) + " and " + compareObj2.get(k));
					if (compareObj1.get(k).equals(compareObj2.get(k)))
					{
						if (compareObj1.get(k).length() == 0)
						{
							formalContext.get(fcRow).add(false);
						}
						else
						{
							formalContext.get(fcRow).add(true);
						}
					}
					else
					{
						formalContext.get(fcRow).add(false);
					}
				}
				fcRow++;
				insertionCounter++;

				// apply reduction only after a fixed number of objects are inserted into FC
				if (insertionCounter % reduceAfterInsertions == 0)
				{
					reducedRows = LukasiewiczReduction(1);
					removeRows(reducedRows);
					//if (reducedRows.size() != reduceAfterInsertions)
					//	System.out.println(reducedRows.size());
					fcRow -= reducedRows.size();
					//System.out.println(reducedRows.size());
				}
			}
		}
		// run the reduction one last time to capture any inserted objects that were missing
		System.out.println();
		reducedRows = LukasiewiczReduction(1);
		removeRows(reducedRows);
		fcRow -= reducedRows.size();

		// just simple code to add the last row where we compare one object to itself
		// and so would have all 1s in this row
		// eg: obj500-obj500 1 1 1 1 1 1 1 1
		i = dataset.size()-1;
		j = i;
		compareObj1 = dataset.get(i);
		compareObj2 = dataset.get(j);
		formalContext.add(new ArrayList<Boolean>());
		fcObjectNames.add("obj" + (i+1) + "-obj" + (j+1));
		for (k = startColumn; k < compareObj1.size()-skipLastColumn; k++)
		{
			if (compareObj1.get(k).equals(compareObj2.get(k)))
			{
				if (compareObj1.get(k).length() == 0)
				{
					formalContext.get(fcRow).add(false);
				}
				else
				{
					formalContext.get(fcRow).add(true);
				}
			}
			else
			{
				formalContext.get(fcRow).add(false);
			}
		}
	}

	public static void convertToApproximateReducedFC(int reduceAfterInsertions)
	{
		System.out.println("Start convertion to approximated reduced FC" );
		int i, j, k, fcRow, insertionCounter;
		double similarity;
		double similarityThreshold = globalSimilarityThreshold;
		ArrayList<String> compareObj1, compareObj2;
		ArrayList<Integer> reducedRows;
		System.out.println(" Threshold = " + similarityThreshold);
		int startColumn = (skipFirstColumn>=1)?1:0;

		if (dataset.size() <=0)
		{
			System.out.println("Dataset not set up before converting to reduced FC");
			return;
		}
		if (reduceAfterInsertions <=0)
		{
			System.out.println("Invalid value put for no of insertions before reduction is applied");
			return;
		}

		fcRow = 0;
		insertionCounter = 0;
		for (i = 0; i < dataset.size()-1; i++)
		{
			compareObj1 = dataset.get(i);
			if (i% 1000 == 0)
				System.out.print(i + ",");
			if (i% 20000 == 0)
				System.out.println();
			// Standard case to always compare non-matching objects is to set j = i+1
			for (j = i+1; j<dataset.size(); j++)
			{
				compareObj2 = dataset.get(j);

				// add a new row to fc
				formalContext.add(new ArrayList<Boolean>());
				fcObjectNames.add("obj" + (i+1) + "-obj" + (j+1));

				// compare the data in the two objects for each attribute
				//for (k = 0; k < compareObj1.size(); k++)
				for (k = startColumn; k < compareObj1.size()-skipLastColumn; k++)
				{
					// Use equality to account for the last column having class values
					if(k == compareObj1.size()-skipLastColumn-1) 
					{
						if(compareObj1.get(k).equals(compareObj2.get(k)))
						{
							formalContext.get(fcRow).add(true);
						}
						else
						{
							formalContext.get(fcRow).add(false);
						}
					}
					// or else use the similarity metric for the feature number values
					else
					{
						similarity=compareNumbers2(compareObj1.get(k), compareObj2.get(k));
						similarity=similarity*100;					
						//if the two points 80% or more similar so put 1 otherwise put 0					
						if(similarity >= similarityThreshold)
						{
							formalContext.get(fcRow).add(true);
						}
						else
						{
							formalContext.get(fcRow).add(false);
						}
					}
				}
				fcRow++;
				insertionCounter++;

				if (insertionCounter % reduceAfterInsertions == 0)
				{
					reducedRows = LukasiewiczReduction(1);
					removeRows(reducedRows);
					fcRow -= reducedRows.size();
				}
			}
		}
		// run the reduction one last time to capture any inserted objects that were missing
		reducedRows = LukasiewiczReduction(1);
		removeRows(reducedRows);
		fcRow -= reducedRows.size();

		// just simple code to add the last row where we compare one object to itself
		// and so would have all 1s in this row
		// eg: obj500-obj500 1 1 1 1 1 1 1 1
		i = dataset.size()-1;
		j = i;
		compareObj1 = dataset.get(i);
		compareObj2 = dataset.get(j);
		formalContext.add(new ArrayList<Boolean>());
		//formalContext.get(fcRow).add("obj" + (i+1) + "-obj" + (j+1));
		fcObjectNames.add("obj" + (i+1) + "-obj" + (j+1));
		//for (k = 0; k < compareObj1.size(); k++)
		for (k = startColumn; k < compareObj1.size()-skipLastColumn; k++)
		{			
			// Use equality to account for the last column having class values
			if(k == compareObj1.size()-skipLastColumn-1) 
			{
				if(compareObj1.get(k).equals(compareObj2.get(k)))
				{
					formalContext.get(fcRow).add(true);
				}
				else
				{
					formalContext.get(fcRow).add(false);
				}
			}
			// or else use the similarity metric for the feature number values
			else
			{
				similarity=compareNumbers2(compareObj1.get(k), compareObj2.get(k));
				similarity=similarity*100;					
				//if the two points 80% or more similar so put 1 otherwise put 0					
				if(similarity >= similarityThreshold)
				{
					formalContext.get(fcRow).add(true);
				}
				else
				{
					formalContext.get(fcRow).add(false);
				}
			}
		}
	}

	public static void writeFCtoFile(String datasetFileName)
	{
		int i,j,value;
		String delimiter = ";"; //replace with "," for good readable format CSV
		FileWriter writer = null;
		String line;
		String filename = datasetFileName.replaceAll(".csv", "FC.csv"); 
		System.out.println("Writing FC to File : " + filename);
		try 
		{
			line = "";

			// Create the file reader
			writer = new FileWriter(filename);

			// Write the attribute names of the formal context in the first line
			for (i = 0; i < attributeNames.size(); i++)
			{
				// The concat() method returns a new String that contains the result of the operation
				// It does not change the string itself so line.concat does not work, line = line.concat is valid
				line = line.concat(delimiter + attributeNames.get(i).toString());
			}
			line = line.concat("\n");
			writer.append(line);

			for (i = 0; i < formalContext.size(); i++)
			{
				line = "";
				line = line.concat(fcObjectNames.get(i) + delimiter);
				for (j = 0; j<formalContext.get(i).size(); j++)
				{
					value = (formalContext.get(i).get(j))?1:0;
					line = line.concat(value + delimiter);
				}
				line = line.concat("\n");
				//System.out.print("FC line "+ (i+1) + "= " + line);
				writer.append(line);
			}
		} 
		catch (Exception e) 
		{
			System.out.println("Exception in writeFCtoFile");
			e.printStackTrace();
		} 
		finally
		{
			try 
			{
				writer.flush();
				writer.close();
			} 
			catch (IOException e) 
			{
				System.out.println("IO Exception in writeFCtoFile");
				e.printStackTrace();
			}
		}
	}

	/* This function just dumps the complete FC contents having 1s and 0s without
	 * any attribute or object names into a file for file matching using other 
	 * software
	 */
	public static void dumpFCtoFile(String datasetFileName)
	{
		String filename = datasetFileName.replaceAll(".csv", "DFC.csv");
		System.out.println("Dumping FC to File : " + filename);
		int i,j,value;
		FileWriter writer = null;
		String line;
		int FC_size = formalContext.size();

		try 
		{
			line = "";

			// Create the file reader
			writer = new FileWriter(filename);

			for (i = 0; i < FC_size; i++)
			{
				line = "";
				for (j = 0; j<formalContext.get(i).size(); j++)
				{
					value = (formalContext.get(i).get(j))?1:0;
					line = line.concat(value + "");
				}
				line = line.concat("\n");
				//System.out.print("FC line "+ (i+1) + "= " + line);
				writer.append(line);
			}
		} 
		catch (Exception e) 
		{
			System.out.println("Exception in dumpFCtoFile");
			e.printStackTrace();
		} 
		finally
		{
			try 
			{
				writer.flush();
				writer.close();
			} 
			catch (IOException e) 
			{
				System.out.println("IO Exception in dumpFCtoFile");
				e.printStackTrace();
			}
		}
	}

	public static void readFCFile(String fileName) 
	{
		System.out.println("Reading Formal Context file : " + fileName);
		fcAttributeNames = new ArrayList<String>();
		BufferedReader fileReader = null;
		String[] tokens;
		int i, fcRow;

		try 
		{
			String line = "";

			// Create the file reader
			fileReader = new BufferedReader(new FileReader(fileName));

			// Read the FC file header to read columns names or skip it
			// we can use this to skip the header line containing the column names if required
			line = fileReader.readLine();

			// extract all the column names from the first line
			tokens = line.split(",|;");
			if (tokens.length > 0)
			{
				// the first column has no attribute name since it has the object names
				// so skip the first token since its an empty string (i=1 instead of 0)
				for (i = 1; i < tokens.length; i++)
				{
					//System.out.println(tokens[i]);
					fcAttributeNames.add(tokens[i]);
				}
			}
			attributeNames = fcAttributeNames;

			fcRow = 0;			
			// Read the file line by line starting from the second line
			while ((line = fileReader.readLine()) != null) 
			{
				// Get all tokens available in line
				tokens = line.split(",|;");  // some files use semicolons as delimiters, so we put support for both , and ;
				if (tokens.length > 0) 
				{
					// insert all tokens into a single inner line of the 2d arraylist
					/* 0 [] []        <- list to put tokens into
					 * 1 []
					 * 2 []
					 * */

					// add a new row in the 2d array for next line in dataset
					formalContext.add(new ArrayList<Boolean>());

					fcObjectNames.add(tokens[0]);
					// iterate through tokens and add them to the 2d array
					for (i = 1; i < tokens.length; i++)
					{
						//System.out.println(tokens[i]);
						if (tokens[i].equalsIgnoreCase(" 1"))
						{
							formalContext.get(fcRow).add(true);
						}
						else
						{
							formalContext.get(fcRow).add(false);
						}
					}
				}
				// Point to the next line in the 2d arraylist
				/* 0 [] [] [] [] [] [] []
				 * 1 []         <- list to setup for next group of tokens
				 * 2 []
				 * */
				fcRow++;
			}		
		} 
		catch (Exception e) 
		{
			System.out.println("Error in FCFileReader !!!");
			e.printStackTrace();
		} 
		finally 
		{
			try 
			{
				fileReader.close();
			} 
			catch (IOException e) 
			{
				System.out.println("Error while closing fileReader of FC!!!");
				e.printStackTrace();
			}
		}
	}

	// read a file containing functional dependencies that have been calculated by one of the 
	// seven fd discovery algorithms from Metanome and the german paper
	// reference : https://hpi.de/naumann/projects/repeatability/data-profiling/fd.html 
	public static void readFDFile(String fileName) 
	{
		System.out.println("Reading Functional Dependency file : " + fileName);
		BufferedReader fileReader = null;
		String[] tokens;
		int i, fdLine = 0, columnNumber;
		fdTable = new ArrayList<ArrayList<Integer>>();

		try 
		{
			String line = "";

			// Create the file reader
			fileReader = new BufferedReader(new FileReader(fileName));

			while ((line = fileReader.readLine()) != null) 
			{
				// set up new row in fdTable for next functional dependency
				fdTable.add(new ArrayList<Integer>());

				// System.out.println("Line " + (fdLine+1));

				// matching delimiters ", " OR "[" OR "]" OR "-->"
				tokens = line.split(", |\\[|\\]|-->"); 
				if (tokens.length > 0)
				{
					for (i = 0; i < tokens.length; i++)
					{
						// some fds do not have a left side so this condition makes sure
						// we are not working on empty string tokens when there is no left side
						// example fd with no left side: []-->chess.csv.column4 
						if (tokens[i].length() > 0)
						{
							// System.out.println(tokens[i]);

							// Note: the following code makes a design limitation that
							// the code will only correctly parse fds with single digit column numbers

							// Go through each column index and extract only the column number
							columnNumber = Character.getNumericValue(tokens[i].charAt(tokens[i].length()-1));
							fdTable.get(fdLine).add(columnNumber);
						}
					}
				}
				// move onto next fd line
				fdLine++;
			}
			System.out.println("Number of FDs : " + fdLine);
		} 
		catch (Exception e) 
		{
			System.out.println("Error in FD FileReader !!!");
			e.printStackTrace();
		} 
		finally 
		{
			try 
			{
				fileReader.close();
			} 
			catch (IOException e) 
			{
				System.out.println("Error while closing fileReader of FD!!!");
				e.printStackTrace();
			}
		}
	}

	/* Take a single FD and extract the forward galois connection of objects from
	 * the left hand side attributes of the FD
	 */
	public static ArrayList<Integer> forwardGaloisConnection(int fdRow)
	{
		boolean objectIsValid = true;
		ArrayList<Integer> validObjects = new ArrayList<Integer>(); 
		int attributeIndex,fcRow;
		int j;

		System.out.print("Forward GC of FD : ");
		for (j = 0; j < fdTable.get(fdRow).size()-1; j++)
		{
			System.out.print(fdTable.get(fdRow).get(j) + ", ");
		}
		System.out.print("--> " + fdTable.get(fdRow).get(j) );
		System.out.println();

		// go through FC and get objects matching left hand side of fd			
		for (fcRow = 0; fcRow < formalContext.size(); fcRow++)
		{
			objectIsValid = true;
			// skip the last element of fd since it is on right hand side of fd
			for (j = 0; j < fdTable.get(fdRow).size()-1; j++)
			{
				attributeIndex = fdTable.get(fdRow).get(j); // sometimes add 1 since array index

				if (!(formalContext.get(fcRow).get(attributeIndex)))
				{
					objectIsValid = false;
					break;
				}
			}
			//System.out.println("checking fc row with fd : " + fcRow + " " + objectIsValid);

			// we have an object in FC which matches with the current FD left hand side
			if (objectIsValid)
			{
				validObjects.add(fcRow);
			}
		}
		return validObjects;
	}

	/* Take a list of objects and extract the closure of attributes for the objects 
	 * Given some set of objects eg:{o1,o3,o9}, attributes are chosen that have 1s for 
	 * all of these objects so {A,C,F}. {A,C,F} is the closure or reverse galois connection
	 * of the set of objects {o1,o3,o9}
	 */
	public static ArrayList<Integer> reverseGaloisConnection(ArrayList<Integer> objects)
	{
		boolean attributeIsValid = true;
		ArrayList<Integer> validAttributes = new ArrayList<Integer>(); 
		int objectIndex,fcColumn;
		int j;

		System.out.print("reverse GC of objects : ");
		for (j = 0; j < objects.size(); j++)
		{
			System.out.print(objects.get(j) + ", ");
		}
		System.out.println();

		if (objects.size() == 0)
		{
			System.out.println("No valid attributes exist for empty set from forward GC");
			return validAttributes;
		}

		// go through FC and get attributes matching the reduced objects
		// start from 1 to skip the obj pair names column
		for (fcColumn = 0; fcColumn < formalContext.get(0).size(); fcColumn++)
		{
			attributeIsValid = true;
			for (j = 0; j < objects.size(); j++)
			{
				objectIndex = objects.get(j);

				if (!(formalContext.get(objectIndex).get(fcColumn)))
				{
					attributeIsValid = false;
					break;
				}
			}
			//System.out.println("checking fc row with fd : " + fcRow + " " + objectIsValid);

			// we have an attribute in FC which has 1 for all of the current group of objects
			if (attributeIsValid)
			{
				validAttributes.add(fcColumn);
			}
		}
		return validAttributes;
	}

	public static void checkFdValidity()
	{
		int rightHandSide, i, validFdCount = 0;
		ArrayList<Integer> validObjects, closure;
		for (i=0;i<fdTable.size();i++)
		{
			System.out.println("Print Forward Galois Connection of FD " + i);
			validObjects = forwardGaloisConnection(i); 
			System.out.println(validObjects);
			closure = reverseGaloisConnection(validObjects);
			System.out.println(closure);

			rightHandSide = fdTable.get(i).get(fdTable.get(i).size() - 1);
			if (closure.contains(rightHandSide))
			{
				System.out.println("Valid");
				validFdCount++;
			}
			else
			{
				System.out.println("Invalid");
			}
		}
		System.out.println("Number of valid FDs = " + validFdCount);
	}

	// The reduction function only gives us a list of rows to remove
	// This function actually does the grunt work of deletion of rows
	public static void removeRows(ArrayList<Integer> rowIndexes)
	{
		int i, removeObjectIndex ;		
		//System.out.println("Deleting the reduced Rows of FC");
		// we go in reverse order since removing an object from FC in the beginning
		// would reduce the indexes of the remaining objects by one and this would 
		// in turn invalidate the other rowIndexes we get from the reduction
		//for (i=rowIndexes.size()-1; i>=0; i--)
		for (i=0; i<rowIndexes.size(); i++)
		{
			removeObjectIndex = rowIndexes.get(i);
			formalContext.remove(removeObjectIndex);
			fcObjectNames.remove(removeObjectIndex);
		}
	}


	// building back the smaller DB from the reduced FC
	public static ArrayList<Integer> buildDBfromReducedFC(ArrayList<String> fcObjectNames)
	{
		System.out.println("Building reduced DB from reduced FC");
		int i;
		ArrayList<Integer> dbObjects = new ArrayList<Integer>();
		Pattern p = Pattern.compile("(\\d*)obj(\\d+)-obj(\\d+)");

		for (i=0;i<fcObjectNames.size();i++)
		{
			String fcObject = fcObjectNames.get(i);
			Matcher m = p.matcher(fcObject);
			if(m.matches())
			{
				// Group 1 is starting FC marker number, 
				// Group 2 is the first object number
				Integer objNum = Integer.parseInt(m.group(2));
				if (!dbObjects.contains(objNum))
				{
					dbObjects.add(objNum);
				}
				// Group 3 is the second object number
				objNum = Integer.parseInt(m.group(3));
				if (!dbObjects.contains(objNum))
				{
					dbObjects.add(objNum);
				}
				//System.out.println(m.group(1) + " " + m.group(2));
			}
		}
		Collections.sort(dbObjects);
		return dbObjects;
	}

	public static void writeReducedDBtoFile(ArrayList<Integer> dbObjects, 
			ArrayList<ArrayList<String>> dataset, ArrayList<String> attributeNames, String datasetFileName)
	{
		String outputFileName = datasetFileName.replaceAll(".csv", "_NR.csv"); 
		System.out.println("Writing reduced DB to file : " + outputFileName);
		int i, j, dbObjectIndex;
		FileWriter writer = null;
		String line;

		try 
		{
			line = "";

			// Create the file reader
			writer = new FileWriter(outputFileName);

			// Write the attribute names of the dataset in the first line
			for (i = 0; i < attributeNames.size(); i++)
			{
				// The concat() method returns a new String that contains the result of the operation
				// It does not change the string itself so line.concat does not work, line = line.concat is valid
				line = line.concat(attributeNames.get(i).toString());
				if (i != attributeNames.size()-1)
					line = line.concat(",");
			}
			line = line.concat("\n");
			writer.append(line);

			for (i = 0; i < dbObjects.size(); i++)
			{
				line = "";
				dbObjectIndex = dbObjects.get(i)-1;
				for (j = 0; j<dataset.get(dbObjectIndex).size(); j++)
				{
					line = line.concat(dataset.get(dbObjectIndex).get(j));
					if (j != dataset.get(dbObjectIndex).size()-1)
						line = line.concat(",");
				}
				line = line.concat("\n");
				writer.append(line);
			}
		} 
		catch (Exception e) 
		{
			System.out.println("Exception in writeReducedDBtoFile");
			e.printStackTrace();
		} 
		finally
		{
			try 
			{
				writer.flush();
				writer.close();
			} 
			catch (IOException e) 
			{
				System.out.println("IO Exception in writeReducedDBtoFile");
				e.printStackTrace();
			}
		}
	}

	/* ///////////////////// START Eman Reduction Code //////////////////////////// */
	// Converted from C++ to Java by Fahad
	// reduces the number of rows
	// Check slides for explanation for the algorithm
	public static ArrayList<Integer> LukasiewiczReduction(float delta)
	{
		//System.out.println("Reducing the Rows of FC");
		int k1, k2, w, m, a, b, min, i, weight, referenceValue;
		ArrayList<Integer> satisfiedIndexes = new ArrayList<Integer>(); 
		ArrayList<Integer> removedIndexes = new ArrayList<Integer>();
		boolean all_satisfy, all_min_smaller;
		//int startColumn = (skipFirstColumn>=1)?1:0;

		//for (k1 = 0; k1 < formalContext.size(); k1++)
		for (k1 = formalContext.size()-1; k1 >= 0; k1--)
		{
			for (k2 = 0; k2 < formalContext.size(); k2++)
			{
				if ((k1 != k2) && (!removedIndexes.contains(k2)))
				{
					all_satisfy = true;
					for (w = 0; w < formalContext.get(0).size(); w++)
					{
						//K1=a is the first object and K2=b is the second object, W to move between between columns  
						a = (formalContext.get(k1).get(w))?1:0;
						b = (formalContext.get(k2).get(w))?1:0;
						m = Math.min(1, 1 - a + b);
						all_satisfy = all_satisfy && (m >= delta);
						if (!all_satisfy)
							break;
					}
					if (all_satisfy)
						satisfiedIndexes.add(k2);
				}
			}
			all_min_smaller = true;
			for (w = 0; w < formalContext.get(0).size(); w++)
			{
				min = Integer.MAX_VALUE;
				for (i = 0; i < satisfiedIndexes.size(); i++)
				{
					weight = (formalContext.get(satisfiedIndexes.get(i)).get(w))?1:0; 
					
						if (weight < min)
							min = weight;
				}
				referenceValue = (formalContext.get(k1).get(w))?1:0;
				// min <= referenceValue   is old code
				// new code fix below
				m = Math.min(1, 1 - min + referenceValue);
				all_min_smaller = all_min_smaller && (m >= delta);
				
				if (!all_min_smaller)
					break;
			}
			if (all_min_smaller)
				removedIndexes.add(k1);

			// remove all objects from set of satisfied indexes for preparation for next check 
			// preparation for next check
			satisfiedIndexes.clear();
		}
		return removedIndexes;
	}

	// reduces the number of columns	
	public static ArrayList<Integer> InverseLukasiewiczReduction(double delta)
	{
		System.out.println("Reducing the Attributes of FC");
		int k1, k2, d, m, a, b, min, i, weight, referenceValue;
		ArrayList<Integer>  sat_indexes = new ArrayList<Integer>(); 
		ArrayList<Integer>  removed_indexes = new ArrayList<Integer>(); 
		boolean all_satisfy, all_min_smaller;

		// k1 and k2 skip first obj columns
		for (k1 = 1; k1 < formalContext.get(0).size(); k1++)
		{

			for (k2 = 1; k2 < formalContext.get(0).size(); k2++)
			{
				if ((k1 != k2) && (!removed_indexes.contains(k2)))
				{
					all_satisfy = true;
					for (d = 0; d < formalContext.size(); d++)
					{
						a = (formalContext.get(d).get(k1))?1:0;
						b = (formalContext.get(d).get(k2))?1:0;
						m = Math.min(1, 1 - a + b);
						all_satisfy = all_satisfy && (m >= delta);
						if (!all_satisfy)
							break;
					}
					if (all_satisfy)
						sat_indexes.add(k2);
				}
			}
			all_min_smaller = true;
			for (d = 0; d < formalContext.size(); d++)
			{
				min = Integer.MAX_VALUE;
				for (i = 0; i < sat_indexes.size(); i++)
				{
					weight = (formalContext.get(d).get(sat_indexes.get(i)))?1:0; 
					if (weight<min)
						min = weight;
				}
				referenceValue = (formalContext.get(d).get(k1))?1:0;
				all_min_smaller = all_min_smaller && (min <= referenceValue);
				if (!all_min_smaller)
					break;
			}
			if (all_min_smaller)
				removed_indexes.add(k1);

			sat_indexes.clear();
		}
		return removed_indexes;
	}
	/* ///////////////////// END Eman Reduction Code //////////////////////////// */


	// Auxiliary functions
	public static void printFC()
	{
		System.out.println("Printing formal context");
		int i,j;
		String value;
		// Print the 2d arraylist to check the formal Context
		for (i = 0; i < formalContext.size(); i++)
		{
			System.out.print(fcObjectNames.get(i) + ", ");
			for (j = 0; j<formalContext.get(i).size(); j++)
			{
				value = (formalContext.get(i).get(j))?"1":"0";
				System.out.print(value);
				if (j<formalContext.get(i).size()-1)
					System.out.print(", ");
			}
			System.out.println();
		}
	}

	public static void printDataset()
	{
		int i,j; 
		String value;
		System.out.println("print dataset");
		// Print the 2d arraylist to check the data
		System.out.println("ATTRIBUTES");
		for (i=0;i<attributeNames.size();i++)
		{
			System.out.print(attributeNames.get(i) + ", ");
		}
		System.out.println("\nDATA");
		for (i = 0; i < dataset.size(); i++)
		{
			for (j = 0; j<dataset.get(i).size(); j++)
			{
				value = dataset.get(i).get(j);
				if (value.length() == 0)
				{
					System.out.print("empty" + ", ");
				}
				else
				{
					System.out.print(value + ", ");
				}
			}
			System.out.println();
		}	
	}

	public static void printFDs()
	{
		int i,j;
		// print fdTable
		System.out.println("Printing FD table");
		for (i = 0; i < fdTable.size(); i++)
		{
			for (j = 0; j<fdTable.get(i).size(); j++)
			{
				System.out.print(fdTable.get(i).get(j) + ", ");
			}
			System.out.println();
		}
	}

	public static float calcRemovedObjectsPercentage(int numRemovedRows)
	{
		System.out.println("Number of rows removed :" + numRemovedRows);
		return (((float)numRemovedRows/formalContext.size()) * 100);		
	}

	public static double compareNumbers2(String str1, String str2)
	{
		double V1, V2, max, distance, similarity;

		V1= Double.parseDouble(str1);
		V2= Double.parseDouble(str2);

		if(V1==V2)
		{ 
			distance=0;
			similarity=1;
		}
		else
		{
			if(V1>V2)
				max=V1;

			else
				max=V2;

			distance= Math.abs(V1-V2);
			similarity=1-(distance/max);
		}

		//double distance= 1+(max-min);
		//calculate percentage of difference between two numbers
		//double similarity=1-((max-min)/distance);

		return similarity;
	}



}
