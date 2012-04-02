//
//  SLSMolecule.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/26/2008.
//
//  This is the model class for the molecule object.  It parses a PDB file, generates a vertex buffer object, and renders that object to the screen

#import "SLSMolecule.h"
// Filetypes
#import "SLSMolecule+PDB.h"
#import "SLSMolecule+SDF.h"

#import "SLSOpenGLESRenderer.h"
#import "SLSOpenGLES20Renderer.h"
#import "Model.h"
NSString *const kSLSMoleculeRenderingStartedNotification = @"MoleculeRenderingStarted";
NSString *const kSLSMoleculeRenderingUpdateNotification = @"MoleculeRenderingUpdate";
NSString *const kSLSMoleculeRenderingEndedNotification = @"MoleculeRenderingEnded";

NSString *const kSLSMoleculeLoadingStartedNotification = @"FileLoadingStarted" ;
NSString *const kSLSMoleculeLoadingUpdateNotification = @"FileLoadingUpdate";
NSString *const kSLSMoleculeLoadingEndedNotification = @"FileLoadingEnded";
#define BOND_LENGTH_LIMIT 3.0f

static sqlite3_stmt *insertMoleculeSQLStatement = nil;
static sqlite3_stmt *insertMetadataSQLStatement = nil;
static sqlite3_stmt *insertAtomSQLStatement = nil;
static sqlite3_stmt *insertBondSQLStatement = nil;

static sqlite3_stmt *updateMoleculeSQLStatement = nil;

static sqlite3_stmt *retrieveMoleculeSQLStatement = nil;
static sqlite3_stmt *retrieveMetadataSQLStatement = nil;
static sqlite3_stmt *retrieveAtomSQLStatement = nil;
static sqlite3_stmt *retrieveBondSQLStatement = nil;

static sqlite3_stmt *deleteMoleculeSQLStatement = nil;
static sqlite3_stmt *deleteMetadataSQLStatement = nil;
static sqlite3_stmt *deleteAtomSQLStatement = nil;
static sqlite3_stmt *deleteBondSQLStatement = nil;


@implementation SLSMolecule

#pragma mark -
#pragma mark Initialization and deallocation

- (id)init;
{
	if (![super init])
		return nil;
	
	numberOfStructures = 1;
	numberOfStructureBeingDisplayed = 1;
	
	filename = nil;
	filenameWithoutExtension = nil;
	title = nil;
	keywords = nil;
	sequence = nil;
	compound = nil;
	source = nil;
	journalTitle = nil;
	journalAuthor = nil;
	journalReference = nil;
	author = nil;
	
	isBeingDisplayed = NO;
	isRenderingCancelled = NO;
	
	previousTerminalAtomValue = nil;
	reverseChainDirection = NO;
	currentVisualizationType = BALLANDSTICK;
	
	isPopulatedFromDatabase = NO;
	databaseKey = 0;
    numberOfAtoms = 187;
	isDoneRendering = NO;
    hasRendered=NO;
	stillCountingAtomsInFirstStructure = YES;
	return self;
}
- (id)initWithModel:(Model *)newModel database:(sqlite3 *)newDatabase;
{
    if (![self init])
		return nil;
    
    database = newDatabase;

	
	filename = [[newModel filename] retain];
	
	NSRange rangeUntilFirstPeriod = [filename rangeOfString:@"."];
	if (rangeUntilFirstPeriod.location == NSNotFound)
		filenameWithoutExtension = [[newModel filename] retain];
	else
		filenameWithoutExtension = [[filename substringToIndex:rangeUntilFirstPeriod.location] retain];
	
	//compound = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
    //    NSLog(@"SQL %@ %@\n",title,filename);
    
    desc=[[newModel desc] retain];
    coord.longitude=newModel.longitude;
    coord.latitude=newModel.latitude;
    
    title=[[newModel title] retain];
    if(database){
    if (insertMoleculeSQLStatement == nil) 
	{
        static char *sql = "INSERT INTO models (filename) VALUES(?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insertMoleculeSQLStatement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        }
    }
	// Bind the query variables.
	sqlite3_bind_text(insertMoleculeSQLStatement, 1, [filename UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(insertMoleculeSQLStatement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insertMoleculeSQLStatement);
    if (success != SQLITE_ERROR) 
	{
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
        databaseKey = sqlite3_last_insert_rowid(database);
    }

    // Wrap all SQLite write operations in a BEGIN, COMMIT block to make writing one operation
	[SLSMolecule beginTransactionWithDatabase:database];

	[self writeMoleculeDataToDatabase];

    [SLSMolecule endTransactionWithDatabase:database];
    }
    
	return self;

}

- (id)initWithFilename:(NSString *)newFilename database:(sqlite3 *)newDatabase title:(NSString *)newTitle;
{
	if (![self init])
		return nil;
	database = newDatabase;
	filename = [newFilename copy];
    title = [newTitle copy];
	
	NSRange rangeUntilFirstPeriod = [filename rangeOfString:@"."];
	if (rangeUntilFirstPeriod.location == NSNotFound)
    {
		filenameWithoutExtension = [filename copy];
    }
	else
    {
		filenameWithoutExtension = [[filename substringToIndex:rangeUntilFirstPeriod.location] retain];	
    }
    //NSLog(@"AA %@ %@\n",title,filename);

	if (insertMoleculeSQLStatement == nil) 
	{
        static char *sql = "INSERT INTO models (filename) VALUES(?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insertMoleculeSQLStatement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        }
    }
	// Bind the query variables.
	sqlite3_bind_text(insertMoleculeSQLStatement, 1, [filename UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(insertMoleculeSQLStatement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insertMoleculeSQLStatement);
    if (success != SQLITE_ERROR) 
	{
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
        databaseKey = sqlite3_last_insert_rowid(database);
    }
	
	//NSError *error = nil;
    numberOfAtoms = -999;
    /*if ([[[filename pathExtension] lowercaseString] isEqualToString:@"sdf"])
    {
        if (![self readFromSDFFileToDatabase:&error])
        {
            return nil;
        }
    }
    else
    {
        if (![self readFromPDBFileToDatabase:&error])
        {
            return nil;
        }
    }*/
	
	return self;
}

- (id)initWithSQLStatement:(sqlite3_stmt *)moleculeRetrievalStatement database:(sqlite3 *)newDatabase;
{
	if (![self init])
		return nil;

	database = newDatabase;
	
	// Retrieve molecule information from the line of the SELECT statement
	//(id,filename,title,compound,format,atom_count,structure_count, centerofmass_x,centerofmass_y,centerofmass_z,minimumposition_x,minimumposition_y,minimumposition_z,maximumposition_x,maximumposition_y,maximumposition_z)
//    const char *sql = "UPDATE models SET title=?, desc=?, filename=?, folder=?, weblink=?, lat=?, lon=?, ver=? WHERE id=?";

	databaseKey = sqlite3_column_int(moleculeRetrievalStatement, 0);
	char *stringResult = (char *)sqlite3_column_text(moleculeRetrievalStatement, 1);
	NSString *sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
	title = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];

	stringResult = (char *)sqlite3_column_text(moleculeRetrievalStatement, 2);
	sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
	desc = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
    
    
    
    stringResult = (char *)sqlite3_column_text(moleculeRetrievalStatement, 3);
	sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
	filename = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
	
	NSRange rangeUntilFirstPeriod = [filename rangeOfString:@"."];
	if (rangeUntilFirstPeriod.location == NSNotFound)
		filenameWithoutExtension = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
	else
		filenameWithoutExtension = [[filename substringToIndex:rangeUntilFirstPeriod.location] retain];
	
    stringResult = (char *)sqlite3_column_text(moleculeRetrievalStatement, 4);
	sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
	folder = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
    
    stringResult = (char *)sqlite3_column_text(moleculeRetrievalStatement, 5);
	sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
	weblink = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
    
    coord.latitude=sqlite3_column_double(moleculeRetrievalStatement, 6);
    coord.longitude=sqlite3_column_double(moleculeRetrievalStatement, 7);
    //double version=sqlite3_column_double(moleculeRetrievalStatement, 8);

    //NSLog(@"%f %f %@ %@ %@ %@ %@ %f\n",coord.latitude,coord.longitude,weblink,folder,filenameWithoutExtension,title,desc,version);
		
	return self;
}

- (void)deleteMolecule;
{
	[self deleteMoleculeDataFromDatabase];

	// Remove the file from disk
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	NSError *error = nil;
	if (![[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:[filename stringByDeletingPathExtension]] error:&error])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not delete file", @"Localized", nil) message:[error localizedDescription]
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles:nil, nil];
		[alert show];
		[alert release];					
		return;
	}
}

- (void)dealloc;
{
    numberOfAtoms = 777;
	[title release];
    [folder release];
    [weblink release];
	[filename release];
    filename = nil;
	[filenameWithoutExtension release];
    filenameWithoutExtension = nil;
	[keywords release];
	[journalAuthor release];
	[journalTitle release];
	[journalReference release];
	[sequence release];
	[compound release];
	[source release];
	[author release];
	[previousTerminalAtomValue release];
	
	[super dealloc];
}

+ (BOOL)isFiletypeSupportedForFile:(NSString *)filePath;
{
	// TODO: Make the categories perform a selector to determine whether this file is supported
	if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"pdb"]) // Uncompressed PDB file
	{
		return YES;
	}
	else if ([[[filePath pathExtension] lowercaseString] isEqualToString:@"gz"]) // Gzipped PDB file
	{
		return YES;
	}
	else
	{
		return NO;
	}
}

#pragma mark -
#pragma mark Database methods

+ (BOOL)beginTransactionWithDatabase:(sqlite3 *)database;
{
	const char *sql1 = "BEGIN EXCLUSIVE TRANSACTION";
	sqlite3_stmt *begin_statement;
	if (sqlite3_prepare_v2(database, sql1, -1, &begin_statement, NULL) != SQLITE_OK)
	{
		return NO;
	}
	if (sqlite3_step(begin_statement) != SQLITE_DONE) 
	{
		return NO;
	}
	sqlite3_finalize(begin_statement);
	return YES;
}

+ (BOOL)endTransactionWithDatabase:(sqlite3 *)database;
{
	const char *sql2 = "COMMIT TRANSACTION";
	sqlite3_stmt *commit_statement;
	if (sqlite3_prepare_v2(database, sql2, -1, &commit_statement, NULL) != SQLITE_OK)
	{
		return NO;
	}
	if (sqlite3_step(commit_statement) != SQLITE_DONE) 
	{
		return NO;
	}
	sqlite3_finalize(commit_statement);
	return YES;
}

+ (void)finalizeStatements;
{
	if (insertMoleculeSQLStatement) sqlite3_finalize(insertMoleculeSQLStatement);
	insertMoleculeSQLStatement = nil;
	if (insertMetadataSQLStatement) sqlite3_finalize(insertMetadataSQLStatement);
	insertMetadataSQLStatement = nil;
	if (insertAtomSQLStatement) sqlite3_finalize(insertAtomSQLStatement);
	insertAtomSQLStatement = nil;
	if (insertBondSQLStatement) sqlite3_finalize(insertBondSQLStatement);
	insertBondSQLStatement = nil;
	if (updateMoleculeSQLStatement) sqlite3_finalize(updateMoleculeSQLStatement);
	updateMoleculeSQLStatement = nil;
	if (retrieveMoleculeSQLStatement) sqlite3_finalize(retrieveMoleculeSQLStatement);
	retrieveMoleculeSQLStatement = nil;
	if (retrieveMetadataSQLStatement) sqlite3_finalize(retrieveMetadataSQLStatement);
	retrieveMetadataSQLStatement = nil;
	if (retrieveAtomSQLStatement) sqlite3_finalize(retrieveAtomSQLStatement);
	retrieveAtomSQLStatement = nil;
	if (retrieveBondSQLStatement) sqlite3_finalize(retrieveBondSQLStatement);
	retrieveBondSQLStatement = nil;
	if (deleteMoleculeSQLStatement) sqlite3_finalize(deleteMoleculeSQLStatement);
	deleteMoleculeSQLStatement = nil;
	if (deleteMetadataSQLStatement) sqlite3_finalize(deleteMetadataSQLStatement);
	deleteMetadataSQLStatement = nil;
	if (deleteAtomSQLStatement) sqlite3_finalize(deleteAtomSQLStatement);
	deleteAtomSQLStatement = nil;
	if (deleteBondSQLStatement) sqlite3_finalize(deleteBondSQLStatement);
	deleteBondSQLStatement = nil;
}

// Write this after all parsing is complete
- (void)writeMoleculeDataToDatabase;
{
	if (updateMoleculeSQLStatement == nil) 
	{
		//const char *sql = "UPDATE molecules SET title=?, compound=?, format=?, atom_count=?, bond_count=?, structure_count=?, centerofmass_x=?, centerofmass_y=?, centerofmass_z=?, minimumposition_x=?, minimumposition_y=?, minimumposition_z=?, maximumposition_x=?, maximumposition_y=?, maximumposition_z=? WHERE id=?";
        const char *sql = "UPDATE models SET title=?, desc=?, filename=?, folder=?, weblink=?, lat=?, lon=?, ver=? WHERE id=?";

        if (sqlite3_prepare_v2(database, sql, -1, &updateMoleculeSQLStatement, NULL) != SQLITE_OK) 
			NSAssert1(0, NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
	}
	// Bind the query variables.
	sqlite3_bind_text(updateMoleculeSQLStatement, 1, [[title stringByReplacingOccurrencesOfString:@"'" withString:@"''"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(updateMoleculeSQLStatement, 2, [[desc stringByReplacingOccurrencesOfString:@"'" withString:@"''"] UTF8String], -1, SQLITE_TRANSIENT);
    sqlite3_bind_text(updateMoleculeSQLStatement, 3, [[filename stringByReplacingOccurrencesOfString:@"'" withString:@"''"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(updateMoleculeSQLStatement, 4, [[folder stringByReplacingOccurrencesOfString:@"'" withString:@"''"] UTF8String], -1, SQLITE_TRANSIENT);
	sqlite3_bind_text(updateMoleculeSQLStatement, 5, [[weblink stringByReplacingOccurrencesOfString:@"'" withString:@"''"] UTF8String], -1, SQLITE_TRANSIENT);

    sqlite3_bind_double(updateMoleculeSQLStatement, 6, (double)coord.latitude);
    sqlite3_bind_double(updateMoleculeSQLStatement, 7, (double)coord.longitude);
    sqlite3_bind_double(updateMoleculeSQLStatement, 8, (double)0);

	sqlite3_bind_int(updateMoleculeSQLStatement, 9, databaseKey);

	// Execute the query.
	int success = sqlite3_step(updateMoleculeSQLStatement);
	// Reset the query for the next use.
	sqlite3_reset(updateMoleculeSQLStatement);
	// Handle errors.
	if (success != SQLITE_DONE) 
		NSAssert1(0, NSLocalizedStringFromTable(@"Error: failed to dehydrate with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));	
}

- (void)addMetadataToDatabase:(NSString *)metadata type:(SLSMetadataType)metadataType;
{
	if (insertMetadataSQLStatement == nil) 
	{
        static char *sql = "INSERT INTO metadata (molecule,type,value) VALUES(?,?,?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insertMetadataSQLStatement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        }
    }
	// Bind the query variables.
	sqlite3_bind_int(insertMetadataSQLStatement, 1, databaseKey);
	sqlite3_bind_int(insertMetadataSQLStatement, 2, metadataType);
	sqlite3_bind_text(insertMetadataSQLStatement, 3, [[metadata stringByReplacingOccurrencesOfString:@"'" withString:@"''"] UTF8String], -1, SQLITE_TRANSIENT);
    int success = sqlite3_step(insertMetadataSQLStatement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insertMetadataSQLStatement);
	if (success != SQLITE_DONE) 
		NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to insert metadata with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));		
}

- (NSInteger)addAtomToDatabase:(SLSAtomType)atomType atPoint:(SLS3DPoint)newPoint structureNumber:(NSInteger)structureNumber residueKey:(SLSResidueType)residueKey;
{
	if (insertAtomSQLStatement == nil) 
	{
        static char *sql = "INSERT INTO atoms (molecule,residue,structure,element,x,y,z) VALUES(?,?,?,?,?,?,?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insertAtomSQLStatement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        }
    }
	// Bind the query variables.
	sqlite3_clear_bindings(insertAtomSQLStatement);
	sqlite3_bind_int(insertAtomSQLStatement, 1, databaseKey);
	sqlite3_bind_int(insertAtomSQLStatement, 2, residueKey);
	sqlite3_bind_int(insertAtomSQLStatement, 3, structureNumber);
	sqlite3_bind_int(insertAtomSQLStatement, 4, atomType);
	sqlite3_bind_double(insertAtomSQLStatement, 5, (double)newPoint.x);
	sqlite3_bind_double(insertAtomSQLStatement, 6, (double)newPoint.y);
	sqlite3_bind_double(insertAtomSQLStatement, 7, (double)newPoint.z);
    int success = sqlite3_step(insertAtomSQLStatement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insertAtomSQLStatement);
    if (success == SQLITE_ERROR) 
	{
		return -1;
        // SQLite provides a method which retrieves the value of the most recently auto-generated primary key sequence
        // in the database. To access this functionality, the table should have a column declared of type 
        // "INTEGER PRIMARY KEY"
    }
	
	if (stillCountingAtomsInFirstStructure)
		numberOfAtoms++;

	return sqlite3_last_insert_rowid(database);
}

// Evaluate using atom IDs here for greater rendering flexibility
- (void)addBondToDatabaseWithStartPoint:(NSValue *)startValue endPoint:(NSValue *)endValue bondType:(SLSBondType)bondType structureNumber:(NSInteger)structureNumber residueKey:(NSInteger)residueKey;
{
	SLS3DPoint startPoint, endPoint;
	if ( (startValue == nil) || (endValue == nil) )
		return;
	[startValue getValue:&startPoint];
	[endValue getValue:&endPoint];

	float bondLength = sqrt((startPoint.x - endPoint.x) * (startPoint.x - endPoint.x) + (startPoint.y - endPoint.y) * (startPoint.y - endPoint.y) + (startPoint.z - endPoint.z) * (startPoint.z - endPoint.z));
	if (bondLength > BOND_LENGTH_LIMIT)
	{
		// Don't allow weird, wrong bonds to be displayed
		return;
	}
	
	if (insertBondSQLStatement == nil) 
	{
        static char *sql = "INSERT INTO bonds (molecule,residue,structure,bond_type,start_x,start_y,start_z,end_x,end_y,end_z) VALUES(?,?,?,?,?,?,?,?,?,?)";
        if (sqlite3_prepare_v2(database, sql, -1, &insertBondSQLStatement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0, NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        }
    }
	// Bind the query variables.
	sqlite3_clear_bindings(insertBondSQLStatement);
	sqlite3_bind_int(insertBondSQLStatement, 1, databaseKey);
	sqlite3_bind_int(insertBondSQLStatement, 2, residueKey);
	sqlite3_bind_int(insertBondSQLStatement, 3, structureNumber);
	sqlite3_bind_int(insertBondSQLStatement, 4, bondType);
	sqlite3_bind_double(insertBondSQLStatement, 5, (double)startPoint.x);
	sqlite3_bind_double(insertBondSQLStatement, 6, (double)startPoint.y);
	sqlite3_bind_double(insertBondSQLStatement, 7, (double)startPoint.z);
	sqlite3_bind_double(insertBondSQLStatement, 8, (double)endPoint.x);
	sqlite3_bind_double(insertBondSQLStatement, 9, (double)endPoint.y);
	sqlite3_bind_double(insertBondSQLStatement, 10, (double)endPoint.z);
    int success = sqlite3_step(insertBondSQLStatement);
    // Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(insertBondSQLStatement);
	if (success != SQLITE_DONE) 
		NSAssert1(0, NSLocalizedStringFromTable(@"Error: failed to insert bond with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));		

	if (stillCountingAtomsInFirstStructure)
		numberOfBonds++;
}

- (void)readMetadataFromDatabaseIfNecessary;
{	
	// Check to make sure metadata has not already been loaded
	if (isPopulatedFromDatabase)
		return;
	
	if (retrieveMetadataSQLStatement == nil) 
	{
		const char *sql = "SELECT * FROM metadata WHERE molecule=?";
		if (sqlite3_prepare_v2(database, sql, -1, &retrieveMetadataSQLStatement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        }
	}
	
	// Bind the query variables.
	sqlite3_bind_int(retrieveMetadataSQLStatement, 1, databaseKey);

	while (sqlite3_step(retrieveMetadataSQLStatement) == SQLITE_ROW) 
	{
		//id, molecule,type,value
		SLSMetadataType metadataType = sqlite3_column_int(retrieveMetadataSQLStatement, 2);
        char *stringResult = (char *)sqlite3_column_text(retrieveMetadataSQLStatement, 3);
		NSString *sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
		
		switch (metadataType)
		{
			case MOLECULESOURCE:  
			{
				[source release];
				source = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
			}; break;
			case MOLECULEAUTHOR:  
			{
				[author release];
				author = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
			}; break;
			case JOURNALAUTHOR:  
			{
				[journalAuthor release];
				journalAuthor = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
			}; break;
			case JOURNALTITLE:  
			{
				[journalTitle release];
				journalTitle = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
			}; break;
			case JOURNALREFERENCE:  
			{
				[journalReference release];
				journalReference = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
			}; break;
			case MOLECULESEQUENCE:  
			{
				[sequence release];
				sequence = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] retain];
			}; break;
		}
	}
	
	// Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(retrieveMetadataSQLStatement);
    isPopulatedFromDatabase = YES;
}

- (void)deleteMoleculeDataFromDatabase;
{
	// Delete the molecule from the SQLite database
	if (deleteMoleculeSQLStatement == nil) 
	{
		const char *sql = "DELETE FROM models WHERE id=?";
		if (sqlite3_prepare_v2(database, sql, -1, &deleteMoleculeSQLStatement, NULL) != SQLITE_OK) 
			NSAssert1(0, NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
	}
	sqlite3_bind_int(deleteMoleculeSQLStatement, 1, databaseKey);
	int success = sqlite3_step(deleteMoleculeSQLStatement);
	sqlite3_reset(deleteMoleculeSQLStatement);
	if (success != SQLITE_DONE) 
		NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to dehydrate with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));	

	// Delete the metadata associated with the molecule from the SQLite database	
	if (deleteMetadataSQLStatement == nil) 
	{
		const char *sql = "DELETE FROM metadata WHERE model=?";
		if (sqlite3_prepare_v2(database, sql, -1, &deleteMetadataSQLStatement, NULL) != SQLITE_OK) 
			NSAssert1(0, NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
	}
	sqlite3_bind_int(deleteMetadataSQLStatement, 1, databaseKey);
	success = sqlite3_step(deleteMetadataSQLStatement);
	sqlite3_reset(deleteMetadataSQLStatement);
	if (success != SQLITE_DONE) 
		NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to dehydrate with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));	

}

- (NSInteger)countAtomsForFirstStructure;
{
    const char *sql = "SELECT COUNT(*) FROM atoms WHERE molecule=? AND structure=?";
	sqlite3_stmt *atomCountingStatement;

    unsigned int totalAtomCount = 0;
    
	if (sqlite3_prepare_v2(database, sql, -1, &atomCountingStatement, NULL) == SQLITE_OK) 
	{
        sqlite3_bind_int(atomCountingStatement, 1, databaseKey);
        sqlite3_bind_int(atomCountingStatement, 2, numberOfStructureBeingDisplayed);
        
        if (sqlite3_step(atomCountingStatement) == SQLITE_ROW)
        {
            totalAtomCount =  sqlite3_column_int(atomCountingStatement, 0);
        }
        else
        {
        }
	}
	sqlite3_finalize(atomCountingStatement);
    
    return totalAtomCount;
}

- (NSInteger)countBondsForFirstStructure;
{
    const char *sql = "SELECT COUNT(*) FROM bonds WHERE molecule=? AND structure=?";
	sqlite3_stmt *bondCountingStatement;
    
    unsigned int totalBondCount = 0;
    
	if (sqlite3_prepare_v2(database, sql, -1, &bondCountingStatement, NULL) == SQLITE_OK) 
	{
        sqlite3_bind_int(bondCountingStatement, 1, databaseKey);
        sqlite3_bind_int(bondCountingStatement, 2, numberOfStructureBeingDisplayed);
        
        if (sqlite3_step(bondCountingStatement) == SQLITE_ROW)
        {
            totalBondCount =  sqlite3_column_int(bondCountingStatement, 0);
        }
        else
        {
        }
	}
	sqlite3_finalize(bondCountingStatement);
    
    return totalBondCount;
}

#pragma mark -
#pragma mark Status notification methods

- (void)showStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSLSMoleculeRenderingStartedNotification object:nil ];
}

- (void)updateStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSLSMoleculeRenderingUpdateNotification object:[NSNumber numberWithDouble:(double)currentFeatureBeingRendered/(double)totalNumberOfFeaturesToRender] ];
}

- (void)hideStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kSLSMoleculeRenderingEndedNotification object:nil ];
}

#pragma mark -
#pragma mark Rendering

- (void)switchToDefaultVisualizationMode;
{
    if ((numberOfAtoms < 600) && (numberOfBonds > 0))
    {
//        self.currentVisualizationType = SPACEFILLING;
        self.currentVisualizationType = BALLANDSTICK;
    }
    else
    {
        self.currentVisualizationType = SPACEFILLING;
    }
    
    [[NSUserDefaults standardUserDefaults] setInteger:currentVisualizationType forKey:@"currentVisualizationMode"];
}


- (BOOL)renderMolecule:(SLSOpenGLESRenderer *)openGLESRenderer;
{
    currentRenderer = openGLESRenderer;
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	isDoneRendering = NO;
	[self performSelectorOnMainThread:@selector(showStatusIndicator) withObject:nil waitUntilDone:NO];
    
    [openGLESRenderer initiateMoleculeRendering];
    
    openGLESRenderer.overallMoleculeScaleFactor = scaleAdjustmentForX;

	currentFeatureBeingRendered = 0;
    /*
	switch(currentVisualizationType)
	{
		case BALLANDSTICK:
		{
            [openGLESRenderer configureBasedOnNumberOfAtoms:[self countAtomsForFirstStructure] numberOfBonds:[self countBondsForFirstStructure]];
			totalNumberOfFeaturesToRender = numberOfAtoms + numberOfBonds;

            openGLESRenderer.bondRadiusScaleFactor = 0.15;
            openGLESRenderer.atomRadiusScaleFactor = 0.35;
			
		[self readAndRenderAtoms:openGLESRenderer];
		[self readAndRenderBonds:openGLESRenderer];
//            openGLESRenderer.atomRadiusScaleFactor = 0.27;
		}; break;
		case SPACEFILLING:
		{
            [openGLESRenderer configureBasedOnNumberOfAtoms:[self countAtomsForFirstStructure] numberOfBonds:0];
			totalNumberOfFeaturesToRender = numberOfAtoms;

            openGLESRenderer.atomRadiusScaleFactor = 1.0;
            [self readAndRenderAtoms:openGLESRenderer];
		}; break;
		case CYLINDRICAL:
		{
            [openGLESRenderer configureBasedOnNumberOfAtoms:0 numberOfBonds:[self countBondsForFirstStructure]];

			totalNumberOfFeaturesToRender = numberOfBonds;

            openGLESRenderer.bondRadiusScaleFactor = 0.15;
			[self readAndRenderBonds:openGLESRenderer];
		}; break;
	}
	*/
	
	if (!isRenderingCancelled)
	{
        [openGLESRenderer bindVertexBuffersForMolecule];
//        }
//        else
//        {
//            [openGLESRenderer performSelectorOnMainThread:@selector(bindVertexBuffersForMolecule) withObject:nil waitUntilDone:YES];   
//        }		
	}
	else
	{
        isBeingDisplayed = NO;
        isRenderingCancelled = NO;
        
        [openGLESRenderer terminateMoleculeRendering];
	}
	
    
	isDoneRendering = YES;
	[self performSelectorOnMainThread:@selector(hideStatusIndicator) withObject:nil waitUntilDone:YES];
    
	[pool release];
    
    currentRenderer = nil;
	return YES;
}

- (void)readAndRenderAtoms:(SLSOpenGLESRenderer *)openGLESRenderer;
{	
	if (isRenderingCancelled)
    {
		return;
    }
    
	if (retrieveAtomSQLStatement == nil) 
	{
		const char *sql = "SELECT residue,structure,element,x,y,z FROM atoms WHERE molecule=? AND structure=?";
        //		const char *sql = "SELECT * FROM atoms WHERE molecule=?";
		if (sqlite3_prepare_v2(database, sql, -1, &retrieveAtomSQLStatement, NULL) != SQLITE_OK) 
		{
            NSAssert1(0, NSLocalizedStringFromTable(@"Error: failed to prepare statement with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        }
	}
	
	// Bind the query variables.
	sqlite3_bind_int(retrieveAtomSQLStatement, 1, databaseKey);
	sqlite3_bind_int(retrieveAtomSQLStatement, 2, numberOfStructureBeingDisplayed);
	
	while ((sqlite3_step(retrieveAtomSQLStatement) == SQLITE_ROW) && !isRenderingCancelled)
	{
		//(id,molecule,residue,structure,element,x,y,z);"
		if ( (currentFeatureBeingRendered % 100) == 0)
        {
			[self performSelectorOnMainThread:@selector(updateStatusIndicator) withObject:nil waitUntilDone:NO];
        }
		currentFeatureBeingRendered++;		
        
		SLSResidueType residueType = sqlite3_column_int(retrieveAtomSQLStatement, 0);
		// TODO: Determine if rendering a particular structure, if not don't render atom 
	//	SLSAtomType atomType = sqlite3_column_int(retrieveAtomSQLStatement, 2);
		SLS3DPoint atomCoordinate;
		atomCoordinate.x = sqlite3_column_double(retrieveAtomSQLStatement, 3);
		atomCoordinate.x -= centerOfMassInX;
		atomCoordinate.x *= scaleAdjustmentForX;
		atomCoordinate.y = sqlite3_column_double(retrieveAtomSQLStatement, 4);
		atomCoordinate.y -= centerOfMassInY;
		atomCoordinate.y *= scaleAdjustmentForX;
		atomCoordinate.z = sqlite3_column_double(retrieveAtomSQLStatement, 5);
		atomCoordinate.z -= centerOfMassInZ;
		atomCoordinate.z *= scaleAdjustmentForX;
		
		if (residueType != WATER)
        {
//			[openGLESRenderer addAtomToVertexBuffers:OXYGEN atPoint:atomCoordinate];
			//[openGLESRenderer addAtomToVertexBuffers:atomType atPoint:atomCoordinate];
        }
	}
	
	// Because we want to reuse the statement, we "reset" it instead of "finalizing" it.
    sqlite3_reset(retrieveAtomSQLStatement);
}

#pragma mark -
#pragma mark Accessors

@synthesize centerOfMassInX, centerOfMassInY, centerOfMassInZ;
@synthesize filename, filenameWithoutExtension, title, keywords, journalAuthor, journalTitle, journalReference, sequence, compound, source, author,desc;
@synthesize isBeingDisplayed, isDoneRendering, isRenderingCancelled;
@synthesize hasRendered;
@synthesize numberOfAtoms, numberOfStructures;
@synthesize previousTerminalAtomValue;
@synthesize currentVisualizationType;
@synthesize numberOfStructureBeingDisplayed;
@synthesize coord;


- (void)setIsBeingDisplayed:(BOOL)newValue;
{
	if (newValue == isBeingDisplayed)
    {
		return;
    }
    
	isBeingDisplayed = newValue;
	if (isBeingDisplayed)
	{
		isRenderingCancelled = NO;
        hasRendered=NO;

	}
	else
	{
		if (!isDoneRendering)
		{
			self.isRenderingCancelled = YES;
            [currentRenderer cancelMoleculeRendering];
			[NSThread sleepForTimeInterval:1.0];
		}
        hasRendered=NO;
	}
}

@end
