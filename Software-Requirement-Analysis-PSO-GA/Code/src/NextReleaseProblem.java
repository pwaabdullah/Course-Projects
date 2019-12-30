//  ZDT3.java
//
//  Author:
//       Antonio J. Nebro <antonio@lcc.uma.es>
//       Juan J. Durillo <durillo@lcc.uma.es>
//
//  Copyright (c) 2011 Antonio J. Nebro, Juan J. Durillo
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
// 
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

import java.util.Arrays;
import java.util.HashMap;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

import javax.swing.tree.TreeNode;

import constraints.BooleanVariable;
import constraints.PropositionalFormula;
import fm.FeatureGroup;
import fm.FeatureModel;
import fm.FeatureModelStatistics;
import fm.FeatureTreeNode;
import fm.RootNode;
import fm.SolitaireFeature;
import fm.XMLFeatureModel;
import jmetal.core.Problem;
import jmetal.core.Solution;
import jmetal.core.Variable;
import jmetal.encodings.solutionType.ArrayRealSolutionType;
import jmetal.encodings.solutionType.BinaryRealSolutionType;
import jmetal.encodings.solutionType.BinarySolutionType;
import jmetal.encodings.solutionType.RealSolutionType;
import jmetal.encodings.variable.Binary;
import jmetal.util.JMException;
import jmetal.util.wrapper.XReal;

/** 
 * Class representing problem ZDT3
 */
public class NextReleaseProblem extends Problem {

	private List<String> featureToDevelopList;
	private List<String> featureLegacyList;
	private List<Integer> featureValueList;
	private List<String> featureList;
	private Map<String,Integer> mapFeatureValue;
	private FeatureModel featureModel;
	/**
	 * Creates a default instance of problem ZDT5 (11 decision variables).
	 * This problem allows only "Binary" representations.
	 */
	public NextReleaseProblem(String solutionType) throws ClassNotFoundException {
		this(solutionType, 11); // 11 variables by default
	} // ZDT5

	/** 
	 * Creates a instance of problem ZDT5
	 * @param numberOfVariables Number of variables.
	 * This problem allows only "Binary" representations.
	 */
	public NextReleaseProblem(String solutionType, Integer numberOfVariables) {
		numberOfVariables_  = 154;//NUMBER OF FEATURES numberOfVariables;
		numberOfObjectives_ = 2;
		numberOfConstraints_= 0;
		problemName_        = "NextReleaseProblem";    

		featureValueList = buildFeatureValueList();

		length_ = new int[numberOfVariables_];
		length_[0] = 3;
		for (int var = 1; var < numberOfVariables_; var++) {
			length_[var] = 3;
		}

		solutionType_ = new BinarySolutionType(this) ; 
		featureList = buildFeatureList();
		featureLegacyList = buildFeatureToKeepE1();
		featureToDevelopList = buildFeatureToDevelopListE1();
		mapFeatureValue = buildFeatureValueDict();
		parse();

		// All the variables of this problem are Binary
		//variableType_ = new Class[numberOfVariables_];
		//for (int var = 0; var < numberOfVariables_; var++){
		//  variableType_[var] = Class.forName("jmetal.base.encodings.variable.Binary") ;
		//} // for
	} //ZDT5

	/** 
	 * Evaluates a solution 
	 * @param solution The solution to evaluate
	 */    
	public void evaluate(Solution solution) {        
		double [] f = new double[numberOfObjectives_] ; 
		//f[0]        = 1 + u((Binary)solution.getDecisionVariables()[0]);         ;
		//f[1]        = 3;//h * g                           ;   
		
		//Calculate the value
		//Binary[] decisions = (Binary[]) solution.getDecisionVariables();
		for(int i =0;i<numberOfVariables_;i++)
		{
			//calculating values			
			Integer sumOfProductsBitsOfaFeature = ((Binary) solution.getDecisionVariables()[i]).bits_.cardinality();
			Integer test2 = mapFeatureValue.get(featureToDevelopList.get(i));
			f[0] = f[0] + sumOfProductsBitsOfaFeature * test2;

		}
		
		


		double totalNCP = 0;
		// iterating over products
		for(int p=0;p<3;p++) {
			
			// assuming constraints only have AND dependency only, we recalculate the product values considering constraints defined in the feature model
			for( PropositionalFormula formula : featureModel.getConstraints() ) {
				boolean featureAND = true;
				for(BooleanVariable test : formula.getVariables()) {
					String id = test.getID();
					int idint = 0;
					
					// features to develop
					for (int i = 0; i<featureToDevelopList.size();i++){
						
						String curVal = featureToDevelopList.get(i);
						  if (curVal.contains(id)){
						    idint = i; break;
						  }
					}
					
					// get i-th binary string
					Binary bit = ((Binary) solution.getDecisionVariables()[idint]);
					featureAND ^= featureAND & bit.getIth(p);
					
					if (featureAND)
					{
						//give penalty to feature values
						Integer test2 = - mapFeatureValue.get(test.getID());
						f[0] = f[0] + 2 * test2;
						
					}
				}
				

			} // end for
			
			//calculating integrity
			int totalCombination = 0;
			double NCP = 0;
			for(int i =0;i<numberOfVariables_;i++)
			{
				boolean chromosomeI = ((Binary) solution.getDecisionVariables()[i]).getIth(p);
				//calculating integrity with legacy features
				if (chromosomeI)
					for (int j = 0;j<featureLegacyList.size();j++)
					{

							boolean chromosomeJ = ((Binary) solution.getDecisionVariables()[j]).getIth(p);
								if (chromosomeI && chromosomeJ)
								{
									//do something
									NCP = NCP + calculateLegacyNCP(i, j);
									totalCombination++;
									
								}

					}
				
				//new variable
				for (int j = 0;j<numberOfVariables_;j++)
				{
					if (i!=j)
					{
						boolean chromosomeJ = ((Binary) solution.getDecisionVariables()[j]).getIth(p);
							if (chromosomeI && chromosomeJ)
							{
								//do something
								int temp = calculateNCP(i,j);
								NCP = NCP + calculateNCP(i, j);
								totalCombination++;
								
							}
					}
				}
			}
			totalNCP = totalNCP + (NCP / totalCombination);
		}

		solution.setObjective(0,-f[0]);
		solution.setObjective(1,-totalNCP);
	} //evaluate


	//Own methods
	public void parse() {

		try {

			String featureModelFile = "/Users/pc/fahim/Dropbox/courses/Software Requirements Engineering/project/REAL-FM-4.xml";
			//String featureModelFile = "/Users/pc/fahim/Dropbox/courses/Software Requirements Engineering/project/SplotAnalysesServlet.xml";

			/* Creates the Feature Model Object
			 * ********************************
			 * - Constant USE_VARIABLE_NAME_AS_ID indicates that if an ID has not been defined for a feature node
			 *   in the XML file the feature name should be used as the ID. 
			 * - Constant SET_ID_AUTOMATICALLY can be used to let the system create an unique ID for feature nodes 
			 *   without an ID specification
			 *   Note: if an ID is specified for a feature node in the XML file it will always prevail
			 */			
			featureModel = new XMLFeatureModel(featureModelFile, XMLFeatureModel.USE_VARIABLE_NAME_AS_ID);

			// Load the XML file and creates the feature model
			featureModel.loadModel();

			// A feature model object contains a feature tree and a set of contraints			
			// Let's traverse the feature tree first. We start at the root feature in depth first search.
			//System.out.println("FEATURE TREE --------------------------------");
			//traverseDFS(featureModel.getRoot(), 0);

			// Now, let's traverse the extra constraints as a CNF formula
			//System.out.println("EXTRA CONSTRAINTS ---------------------------");
			traverseConstraints(featureModel);

			// Now, let's print some statistics about the feature model
			//FeatureModelStatistics stats = new FeatureModelStatistics(featureModel);
			//stats.update();

			//stats.dump();


		} catch (Exception e) {
			// TODO: handle exception
			System.out.println("Error!!");
		}
	}

	public void traverseDFS(FeatureTreeNode node, int tab) {
		for( int j = 0 ; j < tab ; j++ ) {
			//System.out.print("\t");
		}
		// Root Feature
		if ( node instanceof RootNode ) {
			//			System.out.print("Root");
			System.out.println(node.getID());
		}
		// Solitaire Feature
		else if ( node instanceof SolitaireFeature ) {
			// Optional Feature
			if ( ((SolitaireFeature)node).isOptional())
				//				System.out.print("Optional");
				System.out.println(node.getID());
			// Mandatory Feature
			else
				System.out.println(node.getID());
			//				System.out.print("Mandatory");
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
			//			System.out.print("Grouped");
			System.out.println(node.getID());
		}

		//		System.out.print( "(ID=" + node.getID() + ", NAME=" + node.getName() + " )\r\n");
		for( int i = 0 ; i < node.getChildCount() ; i++ ) {
			traverseDFS((FeatureTreeNode )node.getChildAt(i), tab+1);
		}
	}

	public void traverseConstraints(FeatureModel featureModel) {
		for( PropositionalFormula formula : featureModel.getConstraints() ) {
			System.out.println(formula);	
			for(BooleanVariable test : formula.getVariables()) {
				System.out.print(test);
			}
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

	public List<Integer> buildFeatureValueList()
	{
		List<Integer> featureList = Arrays.asList(
				4,
				7,
				1,
				7,
				8,
				9,
				4,
				6,
				2,
				1,
				10,
				6,
				3,
				7,
				2,
				8,
				8,
				8,
				6,
				5,
				5,
				3,
				7,
				5,
				5,
				10,
				6,
				9,
				1,
				2,
				2,
				3,
				5,
				8,
				7,
				4,
				3,
				7,
				9,
				8,
				3,
				5,
				9,
				4,
				10,
				5,
				9,
				1,
				8,
				10,
				10,
				8,
				10,
				4,
				5,
				7,
				7,
				4,
				7,
				6,
				8,
				10,
				2,
				10,
				6,
				3,
				10,
				9,
				5,
				7,
				4,
				8,
				7,
				1,
				10,
				8,
				9,
				1,
				10,
				8,
				4,
				3,
				10,
				10,
				2,
				3,
				1,
				7,
				10,
				8,
				9,
				3,
				10,
				3,
				8,
				2,
				2,
				3,
				8,
				3,
				2,
				9,
				7,
				4,
				9,
				6,
				3,
				10,
				4,
				5,
				3,
				6,
				10,
				10,
				1,
				8,
				10,
				10,
				4,
				4,
				5,
				4,
				3,
				3,
				6,
				6,
				8,
				4,
				2,
				2,
				10,
				9,
				3,
				4,
				2,
				6,
				2,
				7,
				2,
				1,
				10,
				9,
				3,
				7,
				8,
				2,
				10,
				1,
				8,
				7,
				8,
				5,
				9,
				6,
				1,
				3,
				2,
				4,
				2,
				1,
				7,
				10,
				3,
				7,
				1,
				8,
				8,
				3,
				3,
				1,
				7,
				9,
				8,
				3,
				1,
				10,
				4,
				10,
				1,
				7,
				3,
				6,
				4,
				4,
				10,
				9,
				5,
				8,
				3,
				2,
				2,
				8,
				2,
				10,
				2,
				5,
				6,
				7,
				5,
				2,
				5,
				10,
				8,
				4,
				2,
				9,
				9,
				3,
				9,
				10,
				6,
				8,
				3,
				6,
				10,
				6,
				9,
				9,
				10,
				2,
				3,
				7,
				6,
				7,
				6,
				10,
				6,
				3,
				1,
				9,
				1,
				6,
				4,
				4,
				7,
				6,
				4,
				3,
				8,
				6,
				9,
				2,
				8,
				1,
				4,
				10,
				7,
				10,
				8,
				6,
				10,
				8,
				8,
				3,
				4,
				10,
				8,
				7,
				6,
				8,
				4,
				3,
				1,
				5,
				9,
				8,
				9,
				10,
				10,
				1,
				3,
				8,
				9,
				10,
				9,
				8,
				1,
				10,
				5,
				5,
				3,
				6,
				10,
				3,
				10,
				4,
				1,
				1,
				10,
				3
				);

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
	
	public int calculateNCP(int featureid1, int featureid2)
	{
		FeatureTreeNode feature1 = featureModel.getNodeByID(featureToDevelopList.get(featureid1));
		FeatureTreeNode feature2 = featureModel.getNodeByID(featureToDevelopList.get(featureid2));
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
	
	public int calculateLegacyNCP(int featureid1, int featureid2)
	{
		FeatureTreeNode feature1 = featureModel.getNodeByID(featureToDevelopList.get(featureid1));
		FeatureTreeNode feature2 = featureModel.getNodeByID(featureLegacyList.get(featureid2));
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

	public Map<String,Integer> buildFeatureValueDict()
	{
		Map<String,Integer> map = new Hashtable<String, Integer>();

		map.put("eShop",3);
		map.put("store_front",7);
		map.put("homepage",7);
		map.put("_id_1",1);
		map.put("_id_2",9);
		map.put("_id_3",5);
		map.put("_id_5",2);
		map.put("special_offers",3);
		map.put("_id_6",9);
		map.put("_id_8",5);
		map.put("_id_9",5);
		map.put("registration",10);
		map.put("registration_enforcement",9);
		map.put("_id_11",5);
		map.put("register_to_buy",6);
		map.put("_id_12",7);
		map.put("_id_13",8);
		map.put("_id_14",4);
		map.put("shipping_address",4);
		map.put("_id_15",9);
		map.put("_id_16",4);
		map.put("_id_17",4);
		map.put("_id_18",7);
		map.put("_id_19",3);
		map.put("_id_20",5);
		map.put("_id_21",3);
		map.put("_id_22",3);
		map.put("_id_23",7);
		map.put("_id_25",2);
		map.put("_id_26",9);
		map.put("_id_27",3);
		map.put("_id_28",1);
		map.put("_id_29",4);
		map.put("preferences",9);
		map.put("_id_31",6);
		map.put("_id_32",8);
		map.put("_id_33",6);
		map.put("_id_34",4);
		map.put("quick_checkout_profile",7);
		map.put("_id_35",8);
		map.put("user_behaviour_tracking_info",9);
		map.put("catalog",7);
		map.put("product_information",3);
		map.put("product_type",2);
		map.put("eletronic_goods",6);
		map.put("physical_goods",3);
		map.put("services",4);
		map.put("basic_information",10);
		map.put("detailed_information",10);
		map.put("warranty_information",5);
		map.put("customer_reviews",2);
		map.put("associated_assets",10);
		map.put("_id_38",2);
		map.put("_id_39",8);
		map.put("_id_41",5);
		map.put("_id_43",2);
		map.put("_id_44",3);
		map.put("_id_45",4);
		map.put("_id_46",8);
		map.put("_id_47",9);
		map.put("_id_48",7);
		map.put("_id_49",10);
		map.put("_id_50",6);
		map.put("product_variants",8);
		map.put("_id_51",10);
		map.put("size",5);
		map.put("weight",10);
		map.put("availability",5);
		map.put("custom_fields",6);
		map.put("categories",4);
		map.put("categories_catalog",10);
		map.put("_id_52",8);
		map.put("_id_53",6);
		map.put("_id_54",6);
		map.put("_id_55",4);
		map.put("_id_56",3);
		map.put("_id_58",3);
		map.put("_id_59",4);
		map.put("_id_60",8);
		map.put("_id_61",6);
		map.put("category_page",4);
		map.put("_id_62",10);
		map.put("_id_63",9);
		map.put("_id_65",5);
		map.put("_id_66",5);
		map.put("_id_67",2);
		map.put("_id_68",1);
		map.put("_id_69",6);
		map.put("_id_70",5);
		map.put("_id_71",4);
		map.put("_id_72",6);
		map.put("wish_list",9);
		map.put("wish_list_saved_after_session",6);
		map.put("email_wish_list",4);
		map.put("_id_73",9);
		map.put("permissions",2);
		map.put("_id_75",2);
		map.put("_id_76",4);
		map.put("_id_77",10);
		map.put("buy_paths",1);
		map.put("_id_78",5);
		map.put("_id_79",2);
		map.put("_id_80",5);
		map.put("_id_81",6);
		map.put("_id_82",7);
		map.put("_id_83",5);
		map.put("_id_84",5);
		map.put("registered_checkout",3);
		map.put("quick_checkout",9);
		map.put("_id_86",7);
		map.put("_id_87",4);
		map.put("shipping_options",4);
		map.put("_id_88",5);
		map.put("_id_89",2);
		map.put("_id_90",9);
		map.put("_id_91",1);
		map.put("_id_92",1);
		map.put("_id_93",5);
		map.put("_id_95",5);
		map.put("_id_96",8);
		map.put("_id_98",7);
		map.put("_id_99",6);
		map.put("_id_100",10);
		map.put("_id_101",8);
		map.put("shipping_2",2);
		map.put("_id_102",4);
		map.put("_id_103",8);
		map.put("_id_105",7);
		map.put("_id_106",6);
		map.put("_id_107",4);
		map.put("_id_108",2);
		map.put("_id_110",8);
		map.put("_id_111",4);
		map.put("_id_112",8);
		map.put("_id_114",7);
		map.put("_id_115",9);
		map.put("_id_116",8);
		map.put("_id_117",1);
		map.put("_id_118",2);
		map.put("_id_120",2);
		map.put("_id_121",2);
		map.put("_id_122",9);
		map.put("_id_123",4);
		map.put("_id_124",2);
		map.put("_id_125",8);
		map.put("_id_126",4);
		map.put("_id_127",10);
		map.put("_id_128",1);
		map.put("_id_129",2);
		map.put("_id_130",10);
		map.put("_id_132",4);
		map.put("_id_133",3);
		map.put("_id_134",5);
		map.put("_id_135",7);
		map.put("_id_136",1);
		map.put("_id_137",9);
		map.put("_id_138",5);
		map.put("_id_139",3);
		map.put("_id_141",4);
		map.put("_id_142",7);
		map.put("_id_143",8);
		map.put("_id_144",10);
		map.put("buy_paths_288_289",10);
		map.put("buy_paths_288_289_290",10);
		map.put("buy_paths_288_289_291",6);
		map.put("customer_service",6);
		map.put("_id_146",7);
		map.put("_id_147",4);
		map.put("_id_148",1);
		map.put("_id_149",7);
		map.put("_id_150",2);
		map.put("_id_152",3);
		map.put("_id_153",3);
		map.put("_id_154",5);
		map.put("_id_155",2);
		map.put("_id_156",7);
		map.put("_id_158",3);
		map.put("_id_159",8);
		map.put("user_behaviour_tracking",5);
		map.put("_id_160",4);
		map.put("locally_visited_pages",1);
		map.put("external_referring_pages",10);
		map.put("behaviour_tracked_previous_purchases",3);
		map.put("business_management",2);
		map.put("_id_162",9);
		map.put("_id_163",2);
		map.put("physical_goods_fulfillment",10);
		map.put("warehouse_management",4);
		map.put("shipping",6);
		map.put("_id_166",2);
		map.put("_id_167",1);
		map.put("_id_168",4);
		map.put("_id_169",10);
		map.put("_id_171",4);
		map.put("_id_172",1);
		map.put("_id_173",7);
		map.put("_id_174",9);
		map.put("_id_175",10);
		map.put("_id_177",4);
		map.put("_id_178",4);
		map.put("_id_179",9);
		map.put("_id_180",1);
		map.put("_id_181",7);
		map.put("eletronic_goods_fulfillment",9);
		map.put("_id_182",1);
		map.put("_id_183",10);
		map.put("services_fulfillment",5);
		map.put("_id_184",2);
		map.put("_id_185",1);
		map.put("_id_186",5);
		map.put("_id_187",8);
		map.put("customer_preferences",9);
		map.put("_id_189",4);
		map.put("_id_190",10);
		map.put("targeting_criteria_previous_purchases",10);
		map.put("_id_191",1);
		map.put("wish_list_content",4);
		map.put("previously_visited_pages",8);
		map.put("_id_192",7);
		map.put("_id_193",2);
		map.put("_id_194",4);
		map.put("_id_196",4);
		map.put("_id_197",4);
		map.put("_id_199",3);
		map.put("_id_200",4);
		map.put("_id_201",1);
		map.put("_id_203",8);
		map.put("_id_204",5);
		map.put("_id_205",4);
		map.put("_id_206",1);
		map.put("_id_207",5);
		map.put("discounts",8);
		map.put("_id_208",8);
		map.put("_id_209",7);
		map.put("_id_210",1);
		map.put("_id_211",8);
		map.put("_id_212",10);
		map.put("_id_214",8);
		map.put("_id_215",10);
		map.put("_id_216",5);
		map.put("_id_217",6);
		map.put("_id_218",3);
		map.put("_id_219",8);
		map.put("_id_220",2);
		map.put("_id_222",7);
		map.put("_id_223",10);
		map.put("_id_224",1);
		map.put("_id_225",6);
		map.put("_id_226",6);
		map.put("_id_228",2);
		map.put("_id_229",4);
		map.put("_id_230",7);
		map.put("_id_231",4);
		map.put("_id_232",2);
		map.put("_id_233",9);
		map.put("_id_235",4);
		map.put("_id_236",2);
		map.put("_id_237",5);
		map.put("personalized_emails",8);
		map.put("_id_238",6);
		map.put("_id_239",9);
		map.put("_id_240",7);
		map.put("_id_241",1);
		map.put("_id_242",2);
		map.put("inventory_tracking",1);
		map.put("_id_243",7);
		map.put("procurement",1);
		map.put("_id_244",1);
		map.put("_id_245",6);
		map.put("automatic",3);
		map.put("_id_246",3);
		map.put("reporting_and_analysis",8);
		map.put("_id_247",7);
		map.put("_id_248",3);
		map.put("_id_249",7);
		map.put("_id_250",1);
		map.put("fulfillment_system",1);
		map.put("_id_252",6);
		map.put("procurement_system",3);
		map.put("_id_253",6);
		map.put("_id_254",8);
		map.put("_id_255",3);
		map.put("_id_256",7);
		map.put("_id_257",4);
		map.put("_id_258",4);
		map.put("_id_259",3);
		map.put("_id_260",7);
		map.put("_id_261",2);
		map.put("_id_262",5);
		map.put("_id_263",10);

		return map;
	}
	public Boolean findStringInList(List<String> list, String word)
	{
		return list.toString().matches(".*\\b" + word + "\\b.*");
	}

} // ZDT3
