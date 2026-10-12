// lib/models/disease_info.dart

class Treatment {
  final String name;
  final String kind; // 'organic' | 'chemical' | 'cultural'
  final String activeIngredient;
  final String how;
  const Treatment(this.name, this.kind, this.activeIngredient, this.how);
}

class DiseaseInfo {
  final String name;
  final String scientificName;
  final String type; // fungal | bacterial | viral | pest | none
  final String summary;
  final String cause;
  final List<String> effects;
  final List<String> stopNow;
  final List<String> preventSpread;
  final List<String> preventFuture;
  final List<Treatment> treatments;
  final String seeExpertIf;

  const DiseaseInfo({
    required this.name,
    this.scientificName = '',
    required this.type,
    required this.summary,
    required this.cause,
    this.effects = const [],
    this.stopNow = const [],
    this.preventSpread = const [],
    this.preventFuture = const [],
    this.treatments = const [],
    this.seeExpertIf = '',
  });
}

// Keys must match the *cleaned* display names produced by
// TomatoDetector.cleanLabel() in detector.dart.
const Map<String, DiseaseInfo> kDiseaseDb = {
  'Early Blight': DiseaseInfo(
    name: 'Early blight',
    scientificName: 'Alternaria solani',
    type: 'fungal',
    summary:
        'Dark brown spots with concentric rings and yellow halos on lower leaves.',
    cause:
        'Fungus surviving in debris and soil, spread by wind and splash. Favoured by warm, humid weather.',
    effects: [
      'Lower leaves yellow and drop',
      'Reduced photosynthesis, smaller fruit',
      'Sunken stem lesions',
      'Yield loss if untreated',
    ],
    stopNow: [
      'Remove worst lower leaves and bag them',
      'Spray a protectant fungicide',
      'Water at the base only',
      'Mulch the soil',
      'Recheck in 3 days',
    ],
    preventSpread: [
      'Do not work when plants are wet',
      'Disinfect tools between plants',
      'Burn infected leaves; do not compost',
      'Isolate seedlings',
    ],
    preventFuture: [
      'Rotate 2-3 years without tomato/potato',
      'Stake and space for airflow',
      'Remove crop residue at season end',
      'Balanced feeding and steady water',
      'Use clean seed',
      'Tolerant varieties where available',
    ],
    treatments: [
      Treatment('Copper fungicide', 'chemical', 'Copper oxychloride',
          'Spray every 7-10 days covering both leaf surfaces.'),
      Treatment('Broad protectant', 'chemical', 'Mancozeb',
          'Every 7-10 days in wet weather. Follow the label.'),
      Treatment('Bio fungicide', 'organic', 'Bacillus subtilis',
          'Spray early as prevention; repeat per label.'),
      Treatment('Prune and mulch', 'cultural', '',
          'Remove lower 20-30 cm leaves; mulch to stop splash.'),
    ],
    seeExpertIf:
        'More than a third of leaves are affected, or spots appear on fruit.',
  ),

  'Late Blight': DiseaseInfo(
    name: 'Late blight',
    scientificName: 'Phytophthora infestans',
    type: 'fungal',
    summary:
        'Large dark water-soaked blotches with pale grey rims spreading from leaf edges.',
    cause:
        'Water mould spread by wind and rain. Explodes in cool, wet weather.',
    effects: [
      'Leaves and stems collapse quickly',
      'Firm brown patches rot fruit',
      'Whole crop loss within a week',
      'Spreads to nearby tomato and potato fields',
    ],
    stopNow: [
      'Act today - it moves fast',
      'Pull and bag the worst plants',
      'Spray systemic + protectant',
      'Do not overhead water',
      'Daily check until weather dries',
    ],
    preventSpread: [
      'Bag and burn infected plants',
      'Warn neighbours',
      'Clean boots, tools, crates',
      'Do not store with healthy fruit',
    ],
    preventFuture: [
      'Resistant varieties',
      'No tomatoes near potatoes',
      'Drip irrigation',
      'Stake for airflow',
      'Remove volunteer plants',
      'Certified seedlings',
    ],
    treatments: [
      Treatment('Systemic + protectant', 'chemical', 'Metalaxyl-M + mancozeb',
          'First sign, repeat per label, rotate actives.'),
      Treatment('Curative option', 'chemical', 'Cymoxanil + mancozeb',
          'Every 5-7 days in wet weather.'),
      Treatment('Copper protectant', 'chemical', 'Copper hydroxide',
          'Protects healthy leaves only; repeat after rain.'),
      Treatment('Remove and destroy', 'cultural', '',
          'Sprays cannot save already-blackened leaves.'),
    ],
    seeExpertIf: 'Contact your extension officer today.',
  ),

  'Healthy Leaf': DiseaseInfo(
    name: 'Healthy leaf',
    type: 'none',
    summary:
        'Even green leaf with no spots, curling, moulds, or pests visible.',
    cause: 'No disease detected. Keep monitoring lower leaves.',
    effects: ['No yield loss expected from this leaf'],
    stopNow: ['Nothing to treat right now', 'Scout every 3-4 days'],
    preventSpread: [
      'Wash hands and tools between plots',
      'Quarantine new seedlings for a week',
      'Remove yellowing lower leaves early',
    ],
    preventFuture: [
      'Water at base in the morning',
      'Mulch the soil',
      'Stake and prune for airflow',
      'Rotate crops each season',
      'Balanced fertiliser',
      'Check undersides for pests weekly',
    ],
    treatments: [
      Treatment('Bio spray (optional)', 'organic', 'Bacillus subtilis',
          'In wet seasons; per label.'),
      Treatment('Mulch and airflow', 'cultural', '',
          'Cover soil; tie plants so leaves dry fast.'),
    ],
  ),

  'Aphids': DiseaseInfo(
    name: 'Aphids',
    type: 'pest',
    summary:
        'Clusters of small soft-bodied insects, often on the underside of leaves and new shoots.',
    cause:
        'Aphids multiply fast in warm, dry weather and feed on plant sap, excreting honeydew that attracts ants and sooty mould.',
    effects: [
      'Leaves curl, yellow and stunt',
      'Honeydew encourages black sooty mould',
      'Aphids spread viruses',
      'New shoots are worst affected',
    ],
    stopNow: [
      'Spray a strong jet of water to knock them off',
      'Apply insecticidal soap or neem oil',
      'Remove heavily infested shoots',
      'Encourage ladybirds and lacewings',
    ],
    preventSpread: [
      'Check new growth weekly',
      'Avoid excess nitrogen fertiliser',
      'Keep weeds down around beds',
      'Isolate infested potted plants',
    ],
    preventFuture: [
      'Plant companion flowers (marigold, basil)',
      'Use row covers on young plants',
      'Rotate crops each season',
      'Mulch to reduce stress',
      'Encourage beneficial insects',
    ],
    treatments: [
      Treatment('Insecticidal soap', 'organic', 'Potassium salts of fatty acids',
          'Spray undersides thoroughly, repeat every 5-7 days.'),
      Treatment('Neem oil', 'organic', 'Azadirachtin',
          'Spray in the evening; repeat weekly while pests persist.'),
      Treatment('Imidacloprid', 'chemical', 'Imidacloprid',
          'Only if infestation is severe. Follow label; harmful to bees.'),
      Treatment('Water jet', 'cultural', '',
          'Knock colonies off with a strong spray each morning.'),
    ],
    seeExpertIf: 'Plant growth stalls or the infestation spreads to the whole field.',
  ),

  'Bacterial Spot': DiseaseInfo(
    name: 'Bacterial spot',
    type: 'bacterial',
    summary:
        'Small dark water-soaked spots on leaves that turn brown with yellow halos; spots also appear on fruit.',
    cause:
        'Bacteria spread by rain splash, contaminated seed, and tools. Favoured by warm, wet, windy weather.',
    effects: [
      'Leaves drop early, exposing fruit to sunscald',
      'Fruit develops raised dark scabs',
      'Yield and market value drop',
      'Spreads fast in wet seasons',
    ],
    stopNow: [
      'Remove and destroy infected leaves and fruit',
      'Apply copper-based bactericide',
      'Do not work in the field when wet',
      'Improve airflow by staking',
    ],
    preventSpread: [
      'Disinfect tools with 70% alcohol',
      'Avoid overhead irrigation',
      'Do not save seed from infected plants',
      'Wash hands before handling plants',
    ],
    preventFuture: [
      'Use certified disease-free seed',
      'Rotate 2-3 years without tomato/pepper',
      'Choose resistant varieties',
      'Drip irrigation only',
      'Remove crop debris',
      'Space plants for airflow',
    ],
    treatments: [
      Treatment('Copper bactericide', 'chemical', 'Copper hydroxide',
          'Spray every 7-10 days starting at first symptoms.'),
      Treatment('Copper + mancozeb', 'chemical', 'Copper + mancozeb',
          'Use in wet weather; follow label rate.'),
      Treatment('Bio control', 'organic', 'Bacillus subtilis',
          'Preventive spray; repeat per label.'),
    ],
    seeExpertIf: 'Fruit is heavily spotted or more than a quarter of leaves show symptoms.',
  ),

  'Bacterial Canker': DiseaseInfo(
    name: 'Bacterial canker',
    type: 'bacterial',
    summary:
        'Wilting leaves that curl upward, often on one side of the plant, with brown streaks inside the stem.',
    cause:
        'Bacteria that live in seed and soil, entering through wounds. Spreads through pruning tools and splashing water.',
    effects: [
      'Sudden wilting of young leaves',
      'Stems show brown streaks when cut',
      'Fruit may have small bird-eye spots',
      'Plant eventually collapses',
    ],
    stopNow: [
      'Remove and destroy infected plants - do not compost',
      'Disinfect all tools with 70% alcohol',
      'Avoid overhead watering',
      'Do not save seed',
    ],
    preventSpread: [
      'Do not work in the field when wet',
      'Clean tools between every plant',
      'Control weed hosts',
      'Isolate new seedlings',
    ],
    preventFuture: [
      'Use certified seed',
      'Rotate 2-3 years',
      'Graft onto resistant rootstock',
      'Sterilise pots and trays',
      'Choose resistant varieties',
    ],
    treatments: [
      Treatment('Copper bactericide', 'chemical', 'Copper hydroxide',
          'May slow spread; not curative. Follow label.'),
      Treatment('Remove infected plants', 'cultural', '',
          'Once symptoms appear, remove the whole plant.'),
    ],
    seeExpertIf: 'Wilting spreads to more plants within days.',
  ),

  'Leaf Curl': DiseaseInfo(
    name: 'Leaf curl',
    type: 'viral',
    summary:
        'Leaves curl upward or downward, thicken, and become leathery. Growth is stunted.',
    cause:
        'Often caused by viruses (TYLCV) spread by whiteflies, or by herbicide drift and stress.',
    effects: [
      'Growth is stunted',
      'Fewer and smaller fruit',
      'Flowers may drop',
      'Yield can drop by half or more',
    ],
    stopNow: [
      'Remove severely affected plants',
      'Control whiteflies with yellow sticky traps',
      'Apply neem or insecticidal soap',
      'Do not save seed from these plants',
    ],
    preventSpread: [
      'Remove weeds that host whiteflies',
      'Isolate new plants',
      'Use row covers over young plants',
      'Disinfect tools',
    ],
    preventFuture: [
      'Plant resistant varieties',
      'Rotate crops',
      'Remove crop debris',
      'Control whiteflies early',
      'Shade cloth in hot weather',
    ],
    treatments: [
      Treatment('Neem oil', 'organic', 'Azadirachtin',
          'Controls whitefly vector; repeat weekly.'),
      Treatment('Insecticidal soap', 'organic', 'Potassium salts of fatty acids',
          'Spray undersides; repeat every 5-7 days.'),
      Treatment('Yellow sticky traps', 'cultural', '',
          'Hang just above canopy to trap whiteflies.'),
    ],
    seeExpertIf: 'Curling appears on many plants within a week.',
  ),

  'Leafhoppers and Jassids': DiseaseInfo(
    name: 'Leafhoppers and Jassids',
    type: 'pest',
    summary:
        'Small wedge-shaped insects that jump when disturbed. Leaves show stippling and yellow edges.',
    cause:
        'Leafhoppers feed on sap and can transmit viruses. Favoured by warm, dry weather and weedy fields.',
    effects: [
      'Leaves yellow and curl at edges',
      'Stunted growth',
      'Viruses transmitted',
      'Fruit size reduced',
    ],
    stopNow: [
      'Spray neem oil or insecticidal soap',
      'Remove weeds around the field',
      'Use yellow sticky traps',
      'Encourage natural predators',
    ],
    preventSpread: [
      'Keep field borders clean',
      'Avoid moving through the crop when wet',
      'Isolate new plants',
    ],
    preventFuture: [
      'Rotate crops',
      'Plant trap crops',
      'Delay planting to avoid peak season',
      'Use row covers on seedlings',
    ],
    treatments: [
      Treatment('Neem oil', 'organic', 'Azadirachtin',
          'Spray at dusk; repeat weekly.'),
      Treatment('Insecticidal soap', 'organic', 'Potassium salts of fatty acids',
          'Spray undersides thoroughly.'),
      Treatment('Imidacloprid', 'chemical', 'Imidacloprid',
          'Severe cases only; harmful to bees.'),
    ],
    seeExpertIf: 'Yellowing spreads to the whole field despite treatment.',
  ),

  'Molds': DiseaseInfo(
    name: 'Leaf mould',
    type: 'fungal',
    summary:
        'Pale green to yellow patches on the upper leaf surface with olive-green velvety mould underneath.',
    cause:
        'Fungus that thrives in cool, humid conditions with poor airflow. Common in greenhouses and dense plantings.',
    effects: [
      'Leaves drop early',
      'Yield reduced',
      'Fruit quality drops',
      'Spreads in humid conditions',
    ],
    stopNow: [
      'Improve airflow by pruning lower leaves',
      'Reduce humidity: water at base, ventilate',
      'Remove infected leaves',
      'Apply a protectant fungicide',
    ],
    preventSpread: [
      'Do not overhead water',
      'Space plants wider',
      'Remove crop debris at end of season',
      'Disinfect tools',
    ],
    preventFuture: [
      'Resistant varieties',
      'Rotate crops',
      'Drip irrigation',
      'Ventilation in greenhouses',
      'Avoid evening watering',
    ],
    treatments: [
      Treatment('Chlorothalonil', 'chemical', 'Chlorothalonil',
          'Apply every 7-10 days; follow label.'),
      Treatment('Copper fungicide', 'chemical', 'Copper hydroxide',
          'Preventive; repeat per label.'),
      Treatment('Bio fungicide', 'organic', 'Bacillus subtilis',
          'Preventive spray in humid conditions.'),
    ],
    seeExpertIf: 'Mould spreads despite humidity control.',
  ),

  'Mosaic Virus': DiseaseInfo(
    name: 'Tomato mosaic virus',
    type: 'viral',
    summary:
        'Mottled light and dark green patches on leaves; leaves may pucker and distort.',
    cause:
        'Spread mainly by contact - hands, tools, and plant sap. Also in seed. Highly persistent in soil debris.',
    effects: [
      'Mottled, puckered leaves',
      'Stunted growth',
      'Reduced fruit set and size',
      'Yield can drop 25-50%',
    ],
    stopNow: [
      'Remove and destroy infected plants',
      'Wash hands and tools with soap or 70% alcohol',
      'Do not smoke near plants (tobacco carries the virus)',
      'Do not save seed',
    ],
    preventSpread: [
      'Wash hands between plants',
      'Disinfect tools',
      'Remove weeds',
      'Isolate new plants for a week',
    ],
    preventFuture: [
      'Use certified virus-free seed',
      'Resistant varieties',
      'Rotate 2+ years',
      'Remove crop debris',
      'Control aphids (they help spread)',
    ],
    treatments: [
      Treatment('No chemical cure', 'cultural', '',
          'Viruses cannot be cured. Remove infected plants.'),
      Treatment('Aphid control', 'organic', 'Neem oil',
          'Reduces secondary spread by aphids.'),
    ],
    seeExpertIf: 'Symptoms appear on many plants - consider replanting with clean stock.',
  ),

  'Septoria': DiseaseInfo(
    name: 'Septoria leaf spot',
    scientificName: 'Septoria lycopersici',
    type: 'fungal',
    summary:
        'Small circular spots with grey or tan centers and dark borders, starting on lower leaves.',
    cause:
        'Fungus that survives in debris. Spread by splashing water and wind. Favoured by warm, wet weather.',
    effects: [
      'Lower leaves yellow, dry, and drop',
      'Fruit exposed to sunscald',
      'Yield reduced',
      'Spread moves upward fast',
    ],
    stopNow: [
      'Remove and bag affected lower leaves',
      'Apply a protectant fungicide',
      'Water at the base only',
      'Mulch to block splash',
    ],
    preventSpread: [
      'Do not work when plants are wet',
      'Disinfect tools',
      'Remove crop debris',
      'Space plants for airflow',
    ],
    preventFuture: [
      'Rotate 2-3 years',
      'Stake plants',
      'Drip irrigation',
      'Remove old crop residue',
      'Clean seed',
    ],
    treatments: [
      Treatment('Chlorothalonil', 'chemical', 'Chlorothalonil',
          'Spray every 7-10 days; follow label.'),
      Treatment('Copper fungicide', 'chemical', 'Copper octanoate',
          'Preventive spray; repeat per label.'),
      Treatment('Bio fungicide', 'organic', 'Bacillus subtilis',
          'Early-season preventive spray.'),
    ],
    seeExpertIf: 'More than a third of leaves are affected.',
  ),

  'Flea Beetle': DiseaseInfo(
    name: 'Flea beetle',
    type: 'pest',
    summary:
        'Tiny dark beetles that jump when disturbed; leaves show small round shot-holes.',
    cause:
        'Beetles overwinter in soil and emerge in spring, feeding on young leaves. Worst in dry, warm springs.',
    effects: [
      'Small round holes in leaves',
      'Seedlings can be killed',
      'Growth stunted',
      'Susceptible to wilt in hot weather',
    ],
    stopNow: [
      'Apply insecticidal soap or neem',
      'Use row covers on young plants',
      'Place yellow sticky traps',
      'Keep plants well watered',
    ],
    preventSpread: [
      'Remove weeds that host beetles',
      'Rotate crops',
      'Delay planting until beetles are gone',
    ],
    preventFuture: [
      'Row covers over seedlings',
      'Companion plants (radish, catnip)',
      'Mulch to reduce egg-laying',
      'Rotate crops',
      'Encourage predators',
    ],
    treatments: [
      Treatment('Insecticidal soap', 'organic', 'Potassium salts of fatty acids',
          'Spray early morning; repeat weekly.'),
      Treatment('Neem oil', 'organic', 'Azadirachtin',
          'Spray at dusk; repeat weekly.'),
      Treatment('Diatomaceous earth', 'organic', 'Silicon dioxide',
          'Dust around plants; reapply after rain.'),
    ],
    seeExpertIf: 'Seedlings are dying or the crop is losing leaves fast.',
  ),

  'Leafminer': DiseaseInfo(
    name: 'Leafminer',
    type: 'pest',
    summary:
        'Winding white trails inside leaves where larvae tunnel through the tissue.',
    cause:
        'Small flies lay eggs in leaf tissue; larvae mine tunnels. Common in warm, dry weather.',
    effects: [
      'Leaves lose photosynthetic area',
      'Heavy infestations reduce yield',
      'Damage allows secondary infections',
    ],
    stopNow: [
      'Pick and destroy mined leaves',
      'Use yellow sticky traps for adults',
      'Apply neem oil or spinosad',
      'Encourage parasitic wasps',
    ],
    preventSpread: [
      'Remove infested leaves',
      'Keep field free of weeds',
      'Rotate crops',
    ],
    preventFuture: [
      'Row covers on young plants',
      'Rotate crops',
      'Encourage beneficial insects',
      'Remove crop debris',
    ],
    treatments: [
      Treatment('Spinosad', 'organic', 'Spinosad',
          'Spray in the evening; repeat per label.'),
      Treatment('Neem oil', 'organic', 'Azadirachtin',
          'Apply early on larvae; repeat weekly.'),
      Treatment('Yellow sticky traps', 'cultural', '',
          'Mass-trap adults above the canopy.'),
    ],
    seeExpertIf: 'Damage covers most leaves.',
  ),

  'Powdery Mildew': DiseaseInfo(
    name: 'Powdery mildew',
    type: 'fungal',
    summary:
        'White powdery coating on leaves and stems, usually starting on the upper surface.',
    cause:
        'Fungus favoured by warm days, cool nights, and humid air with poor airflow.',
    effects: [
      'Leaves yellow and dry',
      'Growth stunted',
      'Fruit sunscald',
      'Yield reduced',
    ],
    stopNow: [
      'Improve airflow by pruning',
      'Apply potassium bicarbonate or sulfur spray',
      'Remove worst leaves',
      'Avoid overhead watering',
    ],
    preventSpread: [
      'Space plants wider',
      'Do not crowd plants',
      'Remove crop debris',
      'Water at base in the morning',
    ],
    preventFuture: [
      'Resistant varieties',
      'Rotate crops',
      'Good airflow',
      'Balanced feeding (not too much nitrogen)',
    ],
    treatments: [
      Treatment('Potassium bicarbonate', 'organic', 'Potassium bicarbonate',
          'Spray weekly; covers leaf surface.'),
      Treatment('Sulfur spray', 'organic', 'Sulfur',
          'Do not apply in hot weather (>30 C).'),
      Treatment('Bio fungicide', 'organic', 'Bacillus subtilis',
          'Preventive; repeat per label.'),
      Treatment('Myclobutanil', 'chemical', 'Myclobutanil',
          'Severe cases; follow label.'),
    ],
    seeExpertIf: 'Mildew spreads to fruit or most of the crop.',
  ),

  'Yellow Curl Virus': DiseaseInfo(
    name: 'Tomato yellow leaf curl virus',
    scientificName: 'TYLCV',
    type: 'viral',
    summary:
        'Leaves curl upward, become small and yellow at edges. Plants are severely stunted.',
    cause:
        'Virus spread by whiteflies. Common in warm climates with heavy whitefly pressure.',
    effects: [
      'Severe stunting',
      'Flowers drop',
      'Little or no fruit',
      'Yield can be lost entirely',
    ],
    stopNow: [
      'Remove and destroy infected plants',
      'Control whiteflies aggressively',
      'Use yellow sticky traps',
      'Apply neem or insecticidal soap',
    ],
    preventSpread: [
      'Remove weeds that host whiteflies',
      'Isolate new plants',
      'Row covers on seedlings',
      'Do not save seed from infected plants',
    ],
    preventFuture: [
      'Plant resistant varieties (TYLCV-resistant)',
      'Rotate crops',
      'Remove crop debris',
      'Manage whiteflies early',
      'Shade cloth in hot climates',
    ],
    treatments: [
      Treatment('Neem oil', 'organic', 'Azadirachtin',
          'Controls whitefly vector; repeat weekly.'),
      Treatment('Insecticidal soap', 'organic', 'Potassium salts of fatty acids',
          'Spray undersides; repeat every 5-7 days.'),
      Treatment('Imidacloprid', 'chemical', 'Imidacloprid',
          'Severe whitefly pressure; harmful to bees.'),
    ],
    seeExpertIf: 'Symptoms appear on most plants - consider replanting with resistant varieties.',
  ),
};

DiseaseInfo fallbackInfo(String label) => DiseaseInfo(
      name: label,
      type: 'unclear',
      summary:
          'Detected $label. For detailed guidance please consult a local expert.',
      cause: 'Not yet documented in this build.',
      stopNow: ['Consult an extension officer'],
    );

// Shown when no class passes the confidence threshold.
const DiseaseInfo kNoDetectionInfo = DiseaseInfo(
  name: 'No clear disease found',
  type: 'unclear',
  summary:
      'The model did not find a strong match in this photo. Try a closer, '
      'well-lit picture of a single leaf.',
  cause: 'No disease class scored above the confidence threshold.',
  effects: ['No confident diagnosis from this image'],
  stopNow: [
    'Retake the photo close-up, filling the frame with one leaf',
    'Use daylight and keep the leaf in focus',
    'Check the undersides of leaves for pests',
  ],
  preventFuture: [
    'Scout plants every few days',
    'Photograph any new spots early',
  ],
);