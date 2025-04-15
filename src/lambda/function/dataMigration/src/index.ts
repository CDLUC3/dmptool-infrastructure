import { Context, EventBridgeEvent, Handler } from 'aws-lambda';
import { lambdaRequestTracker } from 'pino-lambda';

// Import modules from ../../layers/nodeJS. These should also be included as devDependencies!
import { initializeLogger, LogLevel } from 'dmptool-logger';
import { queryTable } from 'dmptool-rds';
import { getSSMParameter } from 'dmptool-ssm';

// Environment variables
const LOG_LEVEL = process.env.LOG_LEVEL?.toLowerCase() || 'info';

// Initialize the logger
const logger = initializeLogger('DmpExtractorLambda', LogLevel[LOG_LEVEL]);

// Setup the LambdaRequestTracker for the logger
const withRequest = lambdaRequestTracker();

interface DataMigrationRecord {
  migrationFile: string;
  timestamp: string;
}

interface EventBridgeDetails {
  Env: string;
  MigrationFileName: string;
  MigrationStatement: string;
}

/*
  Example input:
    {
      "version": "0",
      "id": "5c9a3747-293c-59d7-dcee-a2210ac034fc",
      "source": "dmphub.uc3dev.cdlib.net:lambda:event_publisher",
      "account": "1234567890",
      "time": "2023-02-14T16:42:06Z",
      "region": "us-west-2",
      "resources": [],
      "detail-type": "DMP Tool Data Migration",
      "detail": {
        "Env": "dev",
        "MigrationFileName": "test.sql",
        "MigrationStatement": "CREATE TABLE `test` ( `id` INT AUTO_INCREMENT PRIMARY KEY ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb3;"
      }
    }
 */

// Lambda Handler - triggered by a scheduled EventBridge event
export const handler: Handler = async (event: EventBridgeEvent<string, EventBridgeDetails>, context: Context) => {
  try {
    logger.debug({ event, context }, 'Received event');

    // Initialize the logger by setting up automatic request tracing.
    withRequest(event, context);

    if (event['detail-type'] !== 'DMP Tool Data Migration' || event.detail.Env === undefined) {
      throw new Error(`Unexpected event type: ${event['detail-type']}`);
    }

    console.log(`DATABSE NAME: ${process.env.RDS_DATABASE}`)

    // Fetch all of the registered data migrations
    const queryResp = await queryTable(
      'SELECT * FROM data_migrations ORDER BY timestamp DESC;'
    ) as { results: DataMigrationRecord[] };

    let alreadyProcessed = false;

    if (Array.isArray(queryResp.results) && queryResp.results.length > 0) {
      // Log the previous data migration name
      logger.debug({
        priorDataMigration: queryResp.results[0]?.migrationFile },
        `Prior migration count: ${queryResp.results.length}.`
      );

      // Check if the current migration has already been processed
      const found = queryResp.results.find((record) => record.migrationFile === event.detail.MigrationFileName);
      alreadyProcessed = found !== undefined;
    }

    if (!alreadyProcessed) {
      const execResults = await queryTable(event.detail.MigrationStatement, []) as { results: any[] };

      if (execResults && execResults.results) {
        // Insert the new data migration record into the database
        await queryTable(
          'INSERT INTO data_migrations (migrationFile, timestamp) VALUES (?, ?);',
          [event.detail.MigrationFileName, event.time]
        );
        logger.info(undefined, `Inserted new data migration record: ${event.detail.MigrationFileName}`);
        return {
          statusCode: 201,
          body: `Inserted new data migration record: ${event.detail.MigrationFileName}`,
        }
      } else {
        logger.fatal(undefined, `Data migration statement did not return results: ${event.detail.MigrationStatement}`);
        return {
          statusCode: 500,
          body: `Data migration statement did not return results: ${event.detail.MigrationStatement}`,
        };
      }
    } else {
      logger.info(undefined, `Data migration record already processed: ${event.detail.MigrationFileName}`);
      return {
        statusCode: 200,
        body: `Data migration record already processed: ${event.detail.MigrationFileName}`,
      };
    }
  } catch (err) {
    logger.fatal(err as Error, 'Error processing data migration event');
    return {
      statusCode: 500,
      body: `Error processing data migration event: ${err}`,
    };
  }
};
