import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.logging.FileHandler;
import java.util.logging.Logger;

import javax.swing.tree.TreeNode;

import jmetal.core.Algorithm;
import jmetal.core.Operator;
import jmetal.core.Problem;
import jmetal.core.SolutionSet;
import jmetal.metaheuristics.nsgaII.NSGAII;
import jmetal.metaheuristics.omopso.OMOPSO;
import jmetal.metaheuristics.omopso.OMOPSO_main;
import jmetal.operators.crossover.CrossoverFactory;
import jmetal.operators.mutation.Mutation;
import jmetal.operators.mutation.MutationFactory;
import jmetal.operators.mutation.NonUniformMutation;
import jmetal.operators.mutation.UniformMutation;
import jmetal.operators.selection.SelectionFactory;
import jmetal.problems.ProblemFactory;
import jmetal.problems.ZDT.ZDT3;
import jmetal.problems.ZDT.ZDT4;
import jmetal.problems.ZDT.ZDT5;
import jmetal.qualityIndicator.QualityIndicator;
import jmetal.util.Configuration;
import jmetal.util.JMException;
import constraints.PropositionalFormula;
import fm.FeatureGroup;
import fm.FeatureModel;
import fm.FeatureModelStatistics;
import fm.FeatureTreeNode;
import fm.RootNode;
import fm.SolitaireFeature;
import fm.XMLFeatureModel;


public class Main {
	  public static Logger      logger_ ;      // Logger object
	  public static FileHandler fileHandler_ ; // FileHandler object

	  public static void main(String [] args)  throws 
      JMException, 
      SecurityException, 
      IOException, 
      ClassNotFoundException  {
		  new Main().parse();
		  
		  
		  Problem   problem   ; // The problem to solve
		    Algorithm algorithm ; // The algorithm to use
		    Operator  crossover ; // Crossover operator
		    Operator  mutation  ; // Mutation operator
		    Operator  selection ; // Selection operator
		    
		    HashMap  parameters ; // Operator parameters
		    
		    QualityIndicator indicators ; // Object to get quality indicators

		    // Logger object and file to store log messages
		    logger_      = Configuration.logger_ ;
		    fileHandler_ = new FileHandler("NSGAII33_main.log"); 
		    logger_.addHandler(fileHandler_) ;
		        
		    indicators = null ;
		    if (args.length == 1) {
		      Object [] params = {"Real"};
		      problem = (new ProblemFactory()).getProblem(args[0],params);
		    } // if
		    else if (args.length == 2) {
		      Object [] params = {"Binary"};
		      problem = (new ProblemFactory()).getProblem(args[0],params);
		      indicators = new QualityIndicator(problem, args[1]) ;
		    } // if
		    else { // Default problem
		      //problem = new Kursawe("Real", 3);
		      //problem = new Kursawe("BinaryReal", 3);
		      //problem = new Water("Real");
		      problem = new NextReleaseProblem("BinaryReal", 30);
		    	//problem = new ZDT4("BinaryReal",3);
		      //problem = new ConstrEx("Real");
		      //problem = new DTLZ1("Real");
		      //problem = new OKA2("Real") ;
		    } // else
		    
		    //algorithm = new NSGAII(problem);
		    algorithm = new BPSO(problem);

		    //For OMOPSO
		    Integer maxIterations = 100 ;
		    Double perturbationIndex = 0.5 ;
		    Double mutationProbability = 1.0/problem.getNumberOfVariables() ;
		    
		    // Algorithm parameters
		    Mutation  uniformMutation ;
		    Mutation nonUniformMutation ;
		    
		    algorithm.setInputParameter("swarmSize",300);
		    algorithm.setInputParameter("archiveSize",100);
		    algorithm.setInputParameter("maxIterations",maxIterations);
		    
		    parameters = new HashMap() ;
		    parameters.put("probability", mutationProbability) ;
		    parameters.put("perturbation", perturbationIndex) ;
		    uniformMutation = new UniformMutation(parameters);
		    
		    parameters = new HashMap() ;
		    parameters.put("probability", mutationProbability) ;
		    parameters.put("perturbation", perturbationIndex) ;
		    parameters.put("maxIterations", maxIterations) ;
		    nonUniformMutation = new NonUniformMutation(parameters);

		    // Add the operators to the algorithm
		    algorithm.addOperator("uniformMutation",uniformMutation);
		    algorithm.addOperator("nonUniformMutation",nonUniformMutation);

//		    // For NSGA
//		    // Algorithm parameters
//		    algorithm.setInputParameter("populationSize",100);
//		    algorithm.setInputParameter("maxEvaluations",25000);
//
//		    // Mutation and Crossover for Real codification 
//		    parameters = new HashMap() ;
//		    parameters.put("probability", 0.9) ;
//		    parameters.put("distributionIndex", 20.0) ;
//		    crossover = CrossoverFactory.getCrossoverOperator("SinglePointCrossover", parameters);                   
//
//		    parameters = new HashMap() ;
//		    parameters.put("probability", 1.0/problem.getNumberOfVariables()) ;
//		    parameters.put("distributionIndex", 20.0) ;
//		    mutation = MutationFactory.getMutationOperator("BitFlipMutation", parameters);                    
//
//		    // Selection Operator 
//		    parameters = null ;
//		    selection = SelectionFactory.getSelectionOperator("BinaryTournament2", parameters) ;                           
//
//		    // Add the operators to the algorithm
//		    algorithm.addOperator("crossover",crossover);
//		    algorithm.addOperator("mutation",mutation);
//		    algorithm.addOperator("selection",selection);
//		    //-----------

		    // Add the indicator object to the algorithm
		    algorithm.setInputParameter("indicators", indicators) ;
		    
		    // Execute the Algorithm
		    long initTime = System.currentTimeMillis();
		    SolutionSet population = algorithm.execute();
		    long estimatedTime = System.currentTimeMillis() - initTime;
		    
		    // Result messages 
		    logger_.info("Total execution time: "+estimatedTime + "ms");
		    logger_.info("Variables values have been writen to file VAR");
		    population.printVariablesToFile("VAR");    
		    logger_.info("Objectives values have been writen to file FUN");
		    population.printObjectivesToFile("FUN");
		  
		    if (indicators != null) {
		      logger_.info("Quality indicators") ;
		      logger_.info("Hypervolume: " + indicators.getHypervolume(population)) ;
		      logger_.info("GD         : " + indicators.getGD(population)) ;
		      logger_.info("IGD        : " + indicators.getIGD(population)) ;
		      logger_.info("Spread     : " + indicators.getSpread(population)) ;
		      logger_.info("Epsilon    : " + indicators.getEpsilon(population)) ;  
		     
		      int evaluations = ((Integer)algorithm.getOutputParameter("evaluations")).intValue();
		      logger_.info("Speed      : " + evaluations + " evaluations") ;      
		    } // if	
}
	  
	  public void parse() {
			
			try {

				//String featureModelFile = "/Users/pc/fahim/Dropbox/courses/Software Requirements Engineering/project/REAL-FM-4.xml";
				String featureModelFile = "/Users/pc/fahim/Dropbox/courses/Software Requirements Engineering/project/SplotAnalysesServlet.xml";
				
				/* Creates the Feature Model Object
				 * ********************************
				 * - Constant USE_VARIABLE_NAME_AS_ID indicates that if an ID has not been defined for a feature node
				 *   in the XML file the feature name should be used as the ID. 
				 * - Constant SET_ID_AUTOMATICALLY can be used to let the system create an unique ID for feature nodes 
				 *   without an ID specification
				 *   Note: if an ID is specified for a feature node in the XML file it will always prevail
				 */			
				FeatureModel featureModel = new XMLFeatureModel(featureModelFile, XMLFeatureModel.USE_VARIABLE_NAME_AS_ID);
				
				// Load the XML file and creates the feature model
				featureModel.loadModel();
				
				// A feature model object contains a feature tree and a set of contraints			
				// Let's traverse the feature tree first. We start at the root feature in depth first search.
				//System.out.println("FEATURE TREE --------------------------------");
				//traverseDFS(featureModel.getRoot(), 0);

				// Now, let's traverse the extra constraints as a CNF formula
				System.out.println("EXTRA CONSTRAINTS ---------------------------");
				traverseConstraints(featureModel);

				// Now, let's print some statistics about the feature model
				FeatureModelStatistics stats = new FeatureModelStatistics(featureModel);
				stats.update();
				
				stats.dump();
				
				System.out.println(calculateNCP(featureModel.getNodeByID("_r_6_7"),featureModel.getNodeByID("_r_6_8")));
				
			} catch (Exception e) {
				// TODO: handle exception
				System.out.println("Kacau gan");
			}
		}
	  
	  public int calculateNCP(FeatureTreeNode feature1, FeatureTreeNode feature2)
	  {
		  TreeNode[] featurePath1 = feature1.getPath();
		  TreeNode[] featurePath2 = feature2.getPath();
		  
		  int ncp = -1;
		  for (int i=0;i<featurePath1.length;i++)
		  {
			  for (int j=i;j<featurePath2.length;j++)
			  {
				  if(featurePath1[i].equals(featurePath2[j]))
					  ncp++;
				  else
					  break;
			  }
		  }
		  return ncp;
	  }
			
	public void traverseDFS(FeatureTreeNode node, int tab) {
			for( int j = 0 ; j < tab ; j++ ) {
				//System.out.print("\t");
			}
			
			// Root Feature
			if ( node instanceof RootNode ) {
//				System.out.print("Root");
				System.out.println(node.getID());
			}
			// Solitaire Feature
			else if ( node instanceof SolitaireFeature ) {
				// Optional Feature
				if ( ((SolitaireFeature)node).isOptional())
//					System.out.print("Optional");
					System.out.println(node.getID());
				// Mandatory Feature
				else
					System.out.println(node.getID());
//					System.out.print("Mandatory");
			}
			// Feature Group
			else if ( node instanceof FeatureGroup ) {
				int minCardinality = ((FeatureGroup)node).getMin();
				int maxCardinality = ((FeatureGroup)node).getMax();
				System.out.println(node.getName());
				System.out.print("Feature Group[" + minCardinality + "," + maxCardinality + "]"); 
			}
			// Grouped feature
			else {
//				System.out.print("Grouped");
				System.out.println(node.getID());
			}
			
//			System.out.print( "(ID=" + node.getID() + ", NAME=" + node.getName() + " )\r\n");
			for( int i = 0 ; i < node.getChildCount() ; i++ ) {
				traverseDFS((FeatureTreeNode )node.getChildAt(i), tab+1);
			}
		}
		
		public void traverseConstraints(FeatureModel featureModel) {
			for( PropositionalFormula formula : featureModel.getConstraints() ) {
				System.out.println(formula);			
			}
		}
		
		public List<String> buildFeatureToDevelopListE1()
		{
			List<String> featureList = Arrays.asList(
					"_id_100",
					"_id_102",
					"_id_105",
					"_id_106",
					"_id_107",
					"_id_110",
					"_id_111",
					"_id_114",
					"_id_115",
					"_id_12",
					"_id_121",
					"_id_122",
					"_id_123",
					"_id_124",
					"_id_125",
					"_id_126",
					"_id_127",
					"_id_128",
					"_id_129",
					"_id_132",
					"_id_133",
					"_id_134",
					"_id_135",
					"_id_136",
					"_id_137",
					"_id_138",
					"_id_141",
					"_id_142",
					"_id_143",
					"_id_147",
					"_id_148",
					"_id_15",
					"_id_152",
					"_id_153",
					"_id_154",
					"_id_155",
					"_id_158",
					"_id_168",
					"_id_17",
					"_id_171",
					"_id_172",
					"_id_173",
					"_id_174",
					"_id_177",
					"_id_178",
					"_id_179",
					"_id_180",
					"_id_182",
					"_id_183",
					"_id_184",
					"_id_185",
					"_id_189",
					"_id_190",
					"_id_191",
					"_id_192",
					"_id_199",
					"_id_200",
					"_id_205",
					"_id_206",
					"_id_207",
					"_id_211",
					"_id_214",
					"_id_215",
					"_id_218",
					"_id_219",
					"_id_22",
					"_id_222",
					"_id_224",
					"_id_228",
					"_id_230",
					"_id_232",
					"_id_235",
					"_id_236",
					"_id_238",
					"_id_239",
					"_id_241",
					"_id_242",
					"_id_243",
					"_id_245",
					"_id_246",
					"_id_25",
					"_id_252",
					"_id_253",
					"_id_259",
					"_id_26",
					"_id_27",
					"_id_28",
					"_id_31",
					"_id_32",
					"_id_33",
					"_id_34",
					"_id_35",
					"_id_38",
					"_id_43",
					"_id_44",
					"_id_45",
					"_id_46",
					"_id_47",
					"_id_48",
					"_id_49",
					"_id_5",
					"_id_51",
					"_id_53",
					"_id_54",
					"_id_55",
					"_id_58",
					"_id_59",
					"_id_65",
					"_id_66",
					"_id_67",
					"_id_68",
					"_id_69",
					"_id_71",
					"_id_72",
					"_id_73",
					"_id_75",
					"_id_76",
					"_id_77",
					"_id_8",
					"_id_81",
					"_id_82",
					"_id_86",
					"_id_88",
					"_id_89",
					"_id_90",
					"_id_91",
					"_id_92",
					"_id_98",
					"availability",
					"behaviour_tracked_previous_purchases",
					"buy_paths_288_289_291",
					"category_page",
					"custom_fields",
					"customer_preferences",
					"customer_reviews",
					"detailed_information",
					"eletronic_goods",
					"email_wish_list",
					"external_referring_pages",
					"fulfillment_system",
					"locally_visited_pages",
					"personalized_emails",
					"physical_goods",
					"previously_visited_pages",
					"procurement_system",
					"quick_checkout_profile",
					"register_to_buy",
					"shipping_2",
					"size",
					"targeting_criteria_previous_purchases",
					"user_behaviour_tracking_info",
					"warranty_information",
					"weight",
					"wish_list_content");
			return featureList;
		}
		
		public List<String> buildFeatureToKeepE1()
		{
			List<String> featureList = Arrays.asList(
					"eShop",
					"store_front",
					"homepage",
					"_id_1",
					"_id_2",
					"_id_3",
					"special_offers",
					"_id_6",
					"_id_9",
					"registration",
					"registration_enforcement",
					"_id_11",
					"_id_13",
					"_id_14",
					"shipping_address",
					"_id_16",
					"_id_18",
					"_id_19",
					"_id_20",
					"_id_21",
					"_id_23",
					"_id_29",
					"preferences",
					"catalog",
					"product_information",
					"product_type",
					"services",
					"basic_information",
					"associated_assets",
					"_id_39",
					"_id_41",
					"_id_50",
					"product_variants",
					"categories",
					"categories_catalog",
					"_id_52",
					"_id_56",
					"_id_60",
					"_id_61",
					"_id_62",
					"_id_63",
					"_id_70",
					"wish_list",
					"wish_list_saved_after_session",
					"permissions",
					"buy_paths",
					"_id_78",
					"_id_79",
					"_id_80",
					"_id_83",
					"_id_84",
					"registered_checkout",
					"quick_checkout",
					"_id_87",
					"shipping_options",
					"_id_93",
					"_id_95",
					"_id_96",
					"_id_99",
					"_id_101",
					"_id_103",
					"_id_108",
					"_id_112",
					"_id_116",
					"_id_117",
					"_id_118",
					"_id_120",
					"_id_130",
					"_id_139",
					"_id_144",
					"buy_paths_288_289",
					"buy_paths_288_289_290",
					"customer_service",
					"_id_146",
					"_id_149",
					"_id_150",
					"_id_156",
					"_id_159",
					"user_behaviour_tracking",
					"_id_160",
					"business_management",
					"_id_162",
					"_id_163",
					"physical_goods_fulfillment",
					"warehouse_management",
					"shipping",
					"_id_166",
					"_id_167",
					"_id_169",
					"_id_175",
					"_id_181",
					"eletronic_goods_fulfillment",
					"services_fulfillment",
					"_id_186",
					"_id_187",
					"_id_193",
					"_id_194",
					"_id_196",
					"_id_197",
					"_id_201",
					"_id_203",
					"_id_204",
					"discounts",
					"_id_208",
					"_id_209",
					"_id_210",
					"_id_212",
					"_id_216",
					"_id_217",
					"_id_220",
					"_id_223",
					"_id_225",
					"_id_226",
					"_id_229",
					"_id_231",
					"_id_233",
					"_id_237",
					"_id_240",
					"inventory_tracking",
					"procurement",
					"_id_244",
					"automatic",
					"reporting_and_analysis",
					"_id_247",
					"_id_248",
					"_id_249",
					"_id_250",
					"_id_254",
					"_id_255",
					"_id_256",
					"_id_257",
					"_id_258",
					"_id_260",
					"_id_261",
					"_id_262",
					"_id_263");
			return featureList;
		}

		public List<String> buildFeatureList()
		{
			List<String> featureList = Arrays.asList(
					"eShop",
					"store_front",
					"homepage",
					"_id_1",
					"_id_2",
					"_id_3",
					"_id_5",
					"special_offers",
					"_id_6",
					"_id_8",
					"_id_9",
					"registration",
					"registration_enforcement",
					"_id_11",
					"register_to_buy",
					"_id_12",
					"_id_13",
					"_id_14",
					"shipping_address",
					"_id_15",
					"_id_16",
					"_id_17",
					"_id_18",
					"_id_19",
					"_id_20",
					"_id_21",
					"_id_22",
					"_id_23",
					"_id_25",
					"_id_26",
					"_id_27",
					"_id_28",
					"_id_29",
					"preferences",
					"_id_31",
					"_id_32",
					"_id_33",
					"_id_34",
					"quick_checkout_profile",
					"_id_35",
					"user_behaviour_tracking_info",
					"catalog",
					"product_information",
					"product_type",
					"eletronic_goods",
					"physical_goods",
					"services",
					"basic_information",
					"detailed_information",
					"warranty_information",
					"customer_reviews",
					"associated_assets",
					"_id_38",
					"_id_39",
					"_id_41",
					"_id_43",
					"_id_44",
					"_id_45",
					"_id_46",
					"_id_47",
					"_id_48",
					"_id_49",
					"_id_50",
					"product_variants",
					"_id_51",
					"size",
					"weight",
					"availability",
					"custom_fields",
					"categories",
					"categories_catalog",
					"_id_52",
					"_id_53",
					"_id_54",
					"_id_55",
					"_id_56",
					"_id_58",
					"_id_59",
					"_id_60",
					"_id_61",
					"category_page",
					"_id_62",
					"_id_63",
					"_id_65",
					"_id_66",
					"_id_67",
					"_id_68",
					"_id_69",
					"_id_70",
					"_id_71",
					"_id_72",
					"wish_list",
					"wish_list_saved_after_session",
					"email_wish_list",
					"_id_73",
					"permissions",
					"_id_75",
					"_id_76",
					"_id_77",
					"buy_paths",
					"_id_78",
					"_id_79",
					"_id_80",
					"_id_81",
					"_id_82",
					"_id_83",
					"_id_84",
					"registered_checkout",
					"quick_checkout",
					"_id_86",
					"_id_87",
					"shipping_options",
					"_id_88",
					"_id_89",
					"_id_90",
					"_id_91",
					"_id_92",
					"_id_93",
					"_id_95",
					"_id_96",
					"_id_98",
					"_id_99",
					"_id_100",
					"_id_101",
					"shipping_2",
					"_id_102",
					"_id_103",
					"_id_105",
					"_id_106",
					"_id_107",
					"_id_108",
					"_id_110",
					"_id_111",
					"_id_112",
					"_id_114",
					"_id_115",
					"_id_116",
					"_id_117",
					"_id_118",
					"_id_120",
					"_id_121",
					"_id_122",
					"_id_123",
					"_id_124",
					"_id_125",
					"_id_126",
					"_id_127",
					"_id_128",
					"_id_129",
					"_id_130",
					"_id_132",
					"_id_133",
					"_id_134",
					"_id_135",
					"_id_136",
					"_id_137",
					"_id_138",
					"_id_139",
					"_id_141",
					"_id_142",
					"_id_143",
					"_id_144",
					"buy_paths_288_289",
					"buy_paths_288_289_290",
					"buy_paths_288_289_291",
					"customer_service",
					"_id_146",
					"_id_147",
					"_id_148",
					"_id_149",
					"_id_150",
					"_id_152",
					"_id_153",
					"_id_154",
					"_id_155",
					"_id_156",
					"_id_158",
					"_id_159",
					"user_behaviour_tracking",
					"_id_160",
					"locally_visited_pages",
					"external_referring_pages",
					"behaviour_tracked_previous_purchases",
					"business_management",
					"_id_162",
					"_id_163",
					"physical_goods_fulfillment",
					"warehouse_management",
					"shipping",
					"_id_166",
					"_id_167",
					"_id_168",
					"_id_169",
					"_id_171",
					"_id_172",
					"_id_173",
					"_id_174",
					"_id_175",
					"_id_177",
					"_id_178",
					"_id_179",
					"_id_180",
					"_id_181",
					"eletronic_goods_fulfillment",
					"_id_182",
					"_id_183",
					"services_fulfillment",
					"_id_184",
					"_id_185",
					"_id_186",
					"_id_187",
					"customer_preferences",
					"_id_189",
					"_id_190",
					"targeting_criteria_previous_purchases",
					"_id_191",
					"wish_list_content",
					"previously_visited_pages",
					"_id_192",
					"_id_193",
					"_id_194",
					"_id_196",
					"_id_197",
					"_id_199",
					"_id_200",
					"_id_201",
					"_id_203",
					"_id_204",
					"_id_205",
					"_id_206",
					"_id_207",
					"discounts",
					"_id_208",
					"_id_209",
					"_id_210",
					"_id_211",
					"_id_212",
					"_id_214",
					"_id_215",
					"_id_216",
					"_id_217",
					"_id_218",
					"_id_219",
					"_id_220",
					"_id_222",
					"_id_223",
					"_id_224",
					"_id_225",
					"_id_226",
					"_id_228",
					"_id_229",
					"_id_230",
					"_id_231",
					"_id_232",
					"_id_233",
					"_id_235",
					"_id_236",
					"_id_237",
					"personalized_emails",
					"_id_238",
					"_id_239",
					"_id_240",
					"_id_241",
					"_id_242",
					"inventory_tracking",
					"_id_243",
					"procurement",
					"_id_244",
					"_id_245",
					"automatic",
					"_id_246",
					"reporting_and_analysis",
					"_id_247",
					"_id_248",
					"_id_249",
					"_id_250",
					"fulfillment_system",
					"_id_252",
					"procurement_system",
					"_id_253",
					"_id_254",
					"_id_255",
					"_id_256",
					"_id_257",
					"_id_258",
					"_id_259",
					"_id_260",
					"_id_261",
					"_id_262",
					"_id_263"
					);
			
			return featureList;
		}

		public Boolean findStringInList(List<String> list, String word)
		{
			return list.toString().matches(".*\\b" + word + "\\b.*");
		}
}
