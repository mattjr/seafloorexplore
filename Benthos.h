//
//  Benthos.h
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/26/2008.
//
//  This is the model class for the model object.  It parses a PDB file, generates a vertex buffer object, and renders that object to the screen

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <sqlite3.h>
#import <MapKit/MapKit.h>

extern NSString *const kBenthosRenderingStartedNotification;
extern NSString *const kBenthosRenderingUpdateNotification;
extern NSString *const kBenthosRenderingEndedNotification;

extern NSString *const kBenthosLoadingStartedNotification;
extern NSString *const kBenthosLoadingUpdateNotification;
extern NSString *const kBenthosLoadingEndedNotification;
@class BenthosOpenGLESRenderer;
@class DownloadedModel;
// TODO: Convert enum to elemental number
typedef enum { CARBON, HYDROGEN, OXYGEN, NITROGEN, SULFUR, PHOSPHOROUS, IRON, UNKNOWN, SILICON, FLUORINE, CHLORINE, BROMINE, IODINE, CALCIUM, ZINC, CADMIUM, SODIUM, MAGNESIUM, NUM_ATOMTYPES } BenthosAtomType;
typedef enum { BALLANDSTICK, SPACEFILLING, CYLINDRICAL, } BenthosVisualizationType;
typedef enum { UNKNOWNRESIDUE, DEOXYADENINE, DEOXYCYTOSINE, DEOXYGUANINE, DEOXYTHYMINE, ADENINE, CYTOSINE, GUANINE, URACIL, GLYCINE, ALANINE, VALINE, 
				LEUCINE, ISOLEUCINE, SERINE, CYSTEINE, THREONINE, METHIONINE, PROLINE, PHENYLALANINE, TYROSINE, TRYPTOPHAN, HISTIDINE,
				LYSINE, ARGININE, ASPARTICACID, GLUTAMICACID, ASPARAGINE, GLUTAMINE, WATER, NUM_RESIDUETYPES } BenthosResidueType;
typedef enum { MODELSOURCE, MODELAUTHOR, JOURNALAUTHOR, JOURNALTITLE, JOURNALREFERENCE, MODELSEQUENCE } BenthosMetadataType;
typedef enum { SINGLEBOND, DOUBLEBOND, TRIPLEBOND } BenthosBondType;

typedef struct { 
	GLfloat x; 
	GLfloat y; 
	GLfloat z; 
} Benthos3DPoint;

@interface BenthosModel : NSObject 
{
	// Metadata from the Protein Data Bank
	unsigned int numberOfAtoms, numberOfBonds, numberOfStructures;
	NSString *filename, *filenameWithoutExtension, *title, *keywords, *journalAuthor, *journalTitle, *journalReference, *sequence, *compound, *source, *author,*desc,*weblink,*folder;
	// Status of the model
    BOOL hasRendered;
	BOOL isBeingDisplayed, isDoneRendering, isRenderingCancelled;
	BenthosVisualizationType currentVisualizationType;
	unsigned int numberOfStructureBeingDisplayed;
	unsigned int totalNumberOfFeaturesToRender, currentFeatureBeingRendered;
	BOOL stillCountingAtomsInFirstStructure;
    CLLocationCoordinate2D coord;
	// A holder for rendering connecting bonds
	NSValue *previousTerminalAtomValue;
	BOOL reverseChainDirection;
		
	// Database values
	sqlite3 *database;
	BOOL isPopulatedFromDatabase;
	NSInteger databaseKey;	
    
    // Model properties for scaling and translation
	float centerOfMassInX, centerOfMassInY, centerOfMassInZ;
	float minimumXPosition, maximumXPosition, minimumYPosition, maximumYPosition, minimumZPosition, maximumZPosition;
	float scaleAdjustmentForX, scaleAdjustmentForY, scaleAdjustmentForZ;

    BenthosOpenGLESRenderer *currentRenderer;
}

@property (readonly) float centerOfMassInX, centerOfMassInY, centerOfMassInZ;
@property (readonly) NSString *filename, *filenameWithoutExtension, *title, *keywords, *journalAuthor, *journalTitle, *journalReference, *sequence, *compound, *source, *author,*desc;
@property (readonly) CLLocationCoordinate2D coord;
@property (readwrite, nonatomic) BOOL isBeingDisplayed, isRenderingCancelled;
@property (readwrite, nonatomic) BOOL hasRendered;

@property (readonly) BOOL isDoneRendering;
@property (readonly) unsigned int numberOfAtoms, numberOfStructures;
@property (readwrite, retain) NSValue *previousTerminalAtomValue;
@property (readwrite, nonatomic) BenthosVisualizationType currentVisualizationType;
@property (readwrite) unsigned int numberOfStructureBeingDisplayed;
- (id)initWithDownloadedModel:(DownloadedModel *)newModel database:(sqlite3 *)newDatabase;

- (id)initWithFilename:(NSString *)newFilename database:(sqlite3 *)newDatabase title:(NSString *)newTitle;
- (id)initWithSQLStatement:(sqlite3_stmt *)modelRetrievalStatement database:(sqlite3 *)newDatabase;
- (void)deleteModel;

+ (BOOL)isFiletypeSupportedForFile:(NSString *)filePath;

// Database methods
+ (BOOL)beginTransactionWithDatabase:(sqlite3 *)database;
+ (BOOL)endTransactionWithDatabase:(sqlite3 *)database;
+ (void)finalizeStatements;
- (void)writeModelDataToDatabase;
- (void)addMetadataToDatabase:(NSString *)metadata type:(BenthosMetadataType)metadataType;
- (NSInteger)addAtomToDatabase:(BenthosAtomType)atomType atPoint:(Benthos3DPoint)newPoint structureNumber:(NSInteger)structureNumber residueKey:(BenthosResidueType)residueKey;
- (void)addBondToDatabaseWithStartPoint:(NSValue *)startValue endPoint:(NSValue *)endValue bondType:(BenthosBondType)bondType structureNumber:(NSInteger)structureNumber residueKey:(NSInteger)residueKey;
- (void)readMetadataFromDatabaseIfNecessary;
- (void)deleteModelDataFromDatabase;
- (NSInteger)countAtomsForFirstStructure;
- (NSInteger)countBondsForFirstStructure;

// Status notification methods
- (void)showStatusIndicator;
- (void)updateStatusIndicator;
- (void)hideStatusIndicator;

// Rendering
- (void)switchToDefaultVisualizationMode;
- (BOOL)renderModel:(BenthosOpenGLESRenderer *)openGLESRenderer;


@end
